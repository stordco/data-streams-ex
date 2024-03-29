defmodule Datadog.DataStreams.Integrations.Kafka do
  @moduledoc """
  Functions for integrating Kafka tracing with DataStreams.

  ## Usage

  Because Elixir does not include a `context` grab bag to pass
  around, we use the OpenTelemetry context to store the current
  DataStreams pathway. If you are not using OpenTelemetry, or
  have a special fan in or fan out situation, you can use the
  respective functions that take a pathway as an argument.

  If you have a basic one message in one message out situation,
  _and_ you have OpenTelemetry already covering your application,
  you can use the `trace_produce/1` and `trace_consume/2` functions.

      require OpenTelemetry.Tracer, as: Tracer

      alias Datadog.DataStreams.Integrations.Kafka, as: DataStreamsKafka

      @doc "Handles a message from Kafka. Receives a message map with partition, topic, and headers."
      @spec handle_message(map()) :: :ok
      def handle_message(message) do
        # NOTE: This does not add the recommended Kafka span attributes.
        Tracer.with_span "\#{message.topic} process" do
          DataStreamsKafka.trace_consume(message, "my_consumer_group")

          # Do work

          Tracer.with_span "\#{new_message.topic} produce" do
            new_message
            |> DataStreamsKafka.trace_produce()
            |> send_to_kafka()
          end
        end
      end

  """

  require OpenTelemetry.Tracer, as: Tracer

  alias Datadog.DataStreams.{Aggregator, Context, Pathway, Propagator, Tags}

  @otel_attribute "pathway.hash"

  @typedoc """
  A general map that contains the topic, partition, and headers atoms. This
  matches the format of `Elsa.elsa_message` by default
  (and will work out of the box), though will need the topic and partition
  added if you are using standard `:brod` (or `kpro`).
  """
  @type message :: map()

  @doc """
  Traces a Kafka message being produced. Uses the pathway in the
  current `Datadog.DataStreams.Context`. Returns a new message with
  the pathway encoded in the header values.
  """
  @spec trace_produce(msg) :: msg when msg: message()
  def trace_produce(message) do
    with {new_message, _pathway} <- trace_produce_with_pathway(Context.get(), message) do
      new_message
    end
  end

  @doc """
  Traces a Kafka message being produced. Returns the new message with the
  pathway encoded in the header values, as well as the new pathway.
  """
  @spec trace_produce_with_pathway(Pathway.t() | nil, msg) :: {msg, Pathway.t()}
        when msg: message()
  def trace_produce_with_pathway(pathway, message) do
    Tracer.with_span "dsm.trace_kafka_produce" do
      edge_tags = produce_edge_tags(message)
      new_pathway = Pathway.set_checkpoint(pathway, edge_tags)

      Tracer.set_attribute(@otel_attribute, to_string(new_pathway.hash))

      new_headers = Propagator.encode_header(message.headers, new_pathway)
      {%{message | headers: new_headers}, new_pathway}
    end
  end

  @spec produce_edge_tags(message()) :: Tags.input()
  defp produce_edge_tags(message) do
    message
    |> Map.take([:topic, :partition])
    |> Map.merge(%{type: "kafka", direction: "out"})
  end

  @doc """
  Tracks Kafka produce events via their offset. This is used by Datadog
  to calculate the lag without requiring the consumer to be on and
  reading trace headers.
  """
  @spec track_produce(String.t(), non_neg_integer(), integer()) :: :ok
  def track_produce(topic, partition, offset) do
    Aggregator.add(%Aggregator.Offset{
      offset: offset,
      timestamp: :erlang.system_time(:nanosecond),
      type: :produce,
      tags: %{
        "partition" => partition,
        "topic" => topic,
        "type" => "kafka_produce"
      }
    })
  end

  @doc """
  Traces a Kafka message being consumed. Requires the current Kafka
  consumer group. Uses the pathway in the current
  `Datadog.DataStreams.Context`.
  """
  @spec trace_consume(message(), String.t()) :: Pathway.t()
  def trace_consume(message, consumer_group) do
    trace_consume_with_pathway(Context.get(), message, consumer_group)
  end

  @doc """
  Traces a Kafka message being consumed. Requires the current Kafka
  consumer group.

  Do not pass the resulting pathway from this function to another call
  of `trace_consume_with_pathway`, as it will modify the pathway incorrectly.
  """
  @spec trace_consume_with_pathway(Pathway.t() | nil, message(), String.t()) :: Pathway.t()
  def trace_consume_with_pathway(pathway, message, consumer_group) do
    Tracer.with_span "dsm.trace_kafka_consume" do
      edge_tags = consume_edge_tags(message, consumer_group)

      new_pathway =
        case Propagator.decode_header(message.headers) do
          nil ->
            Pathway.set_checkpoint(pathway, edge_tags)

          decoded_pathway ->
            Pathway.set_checkpoint(decoded_pathway, edge_tags)
        end

      Tracer.set_attribute(@otel_attribute, to_string(new_pathway.hash))
      new_pathway
    end
  end

  @spec consume_edge_tags(message(), String.t()) :: Tags.input()
  defp consume_edge_tags(message, consumer_group) do
    message
    |> Map.take([:topic, :partition])
    |> Map.merge(%{type: "kafka", direction: "in", group: consumer_group})
  end

  @doc """
  Tracks Kafka produce events via their offset. This is used by Datadog
  to calculate the lag without requiring the consumer to be on and
  reading trace headers.
  """
  @spec track_consume(String.t(), String.t(), non_neg_integer(), integer()) :: :ok
  def track_consume(group, topic, partition, offset) do
    Aggregator.add(%Aggregator.Offset{
      offset: offset,
      timestamp: :erlang.system_time(:nanosecond),
      type: :commit,
      tags: %{
        "consumer_group" => group,
        "partition" => partition,
        "topic" => topic,
        "type" => "kafka_commit"
      }
    })
  end
end
