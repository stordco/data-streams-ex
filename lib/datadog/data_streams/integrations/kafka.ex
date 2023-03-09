defmodule Datadog.DataStreams.Integrations.Kafka do
  @moduledoc """
  Functions for integrating Kafka tracing with DataStreams.
  """

  alias Datadog.DataStreams.{Context, Pathway, Propagator}

  @typedoc """
  A general map that contains the topic, partition, and headers. This
  matches the format of `Elsa.elsa_message` by default
  (and will work out of the box), though will need the topic and partition
  added if you are using standard `:brod` (or `kpro`).
  """
  @type message :: %{
          optional(:topic) => String.t(),
          optional(:partition) => non_neg_integer(),
          optional(:headers) => list({binary(), binary()})
        }

  @doc """
  Traces a Kafka message being produced. Uses the pathway in the
  current `Datadog.DataStreams.Context`. Returns a new message with
  the pathway encoded in the header values.
  """
  @spec trace_produce(message()) :: message()
  def trace_produce(message) do
    edge_tags = produce_edge_tags(message)
    new_pathway = Context.set_checkpoint(edge_tags)
    new_headers = Propagator.encode_header(message.headers, new_pathway)
    %{message | headers: new_headers}
  end

  @doc """
  Traces a Kafka message being produced. Returns the new message with the
  pathway encoded in the header values, as well as the new pathway.
  """
  @spec trace_produce_with_pathway(Pathway.t(), message()) :: {message(), Pathway.t()}
  def trace_produce_with_pathway(pathway, message) do
    edge_tags = produce_edge_tags(message)
    new_pathway = Pathway.set_checkpoint(pathway, edge_tags)
    new_headers = Propagator.encode_header(message.headers, new_pathway)
    {%{message | headers: new_headers}, new_pathway}
  end

  @spec produce_edge_tags(message()) :: list(String.t())
  defp produce_edge_tags(message) do
    message
    |> Map.take([:topic, :partition])
    |> Map.merge(%{type: "kafka", direction: "out"})
    |> Enum.map(fn {k, v} -> to_string(k) <> ":" <> to_string(v) end)
  end

  @doc """
  Traces a Kafka message being consumed. Requires the current Kafka
  consumer group. Uses the pathway in the current
  `Datadog.DataStreams.Context`.
  """
  @spec trace_consume(message(), String.t()) :: Pathway.t()
  def trace_consume(message, consumer_group) do
    edge_tags = consume_edge_tags(message, consumer_group)

    case Propagator.decode_header(message.headers) do
      nil ->
        Context.set_checkpoint(edge_tags)

      pathway ->
        pathway
        |> Context.set()
        |> Pathway.set_checkpoint(edge_tags)
    end
  end

  @doc """
  Traces a Kafka message being consumed. Requires the current Kafka
  consumer group.

  Do not pass the resulting pathway from this function to another call
  of `trace_consume_with_pathway`, as it will modify the pathway incorrectly.
  """
  @spec trace_consume_with_pathway(Pathway.t(), message(), String.t()) :: Pathway.t()
  def trace_consume_with_pathway(pathway, message, consumer_group) do
    edge_tags = consume_edge_tags(message, consumer_group)

    case Propagator.decode_header(message.headers) do
      nil ->
        Pathway.set_checkpoint(pathway, edge_tags)

      decoded_pathway ->
        Pathway.set_checkpoint(decoded_pathway, edge_tags)
    end
  end

  @spec consume_edge_tags(message(), String.t()) :: list(String.t())
  defp consume_edge_tags(message, consumer_group) do
    message
    |> Map.take([:topic, :partition])
    |> Map.merge(%{type: "kafka", direction: "in", group: consumer_group})
    |> Enum.map(fn {k, v} -> to_string(k) <> ":" <> to_string(v) end)
  end
end
