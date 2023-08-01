defmodule Datadog.DataStreams.Aggregator do
  @moduledoc """
  A `GenServer` instance responsible for aggregating many points of data
  together into 10 second buckets, and then sending them to the Datadog
  agent. It holds many structs in its memory, looking something like this:

  ```mermaid
  graph TD
      aggregator[Datadog.DataStreams.Aggregator]
      aggregator --> bucket[Datadog.DataStreams.Aggregator.Bucket]
      bucket --> group[Datadog.DataStreams.Aggregator.Group]
  ```

  When adding data, the calling code will create a new
  `Datadog.DataStreams.Aggregator.Point` which contains all of the needed
  data. It will then call `#{__MODULE__}.add/1` to add that point of data to the
  aggregator, where the aggregator will find (or create) a bucket that matches
  the 10 second window for the point. It will then find (or create) a group in
  that bucket based on the point's `hash`. Once the group is found, the
  `pathway_latency` and `edge_latency` `Datadog.Sketch` will be updated with
  the new latency.

  Every 10 seconds the aggregator will convert all non active (outside the 10
  second window) to a `Datadog.DataStreams.Payload`, encode it, and send it to
  the Datadog agent. If there is an error sending the payload, the old payloads
  are still removed from memory, but the
  `datadog.datastreams.aggregator.flush_errors.count` telemetry metric is
  incremented.
  """

  use GenServer

  require Logger

  alias Datadog.DataStreams.{Aggregator, Config, Payload, Transport}

  @send_interval 10_000

  @doc """
  Starts a new `#{__MODULE__}` instance. This takes no options as it
  uses the global `Datadog.DataStreams.Config` module. It is also started
  by the `Datadog.DataStreams.Application` and should not need to be started
  manually.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(_opts) do
    opts = [enabled?: Config.agent_enabled?()]
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Adds new metrics to the aggregator.

  Note, this function will still return `:ok` if the aggregator is disabled.

  ## Examples

      iex> :ok = Aggregator.add(%Aggregator.Point{})

      iex> :ok = Aggregator.add(%Aggregator.Offset{})

  """
  @spec add(Aggregator.Point.t() | Aggregator.Offset.t()) :: :ok
  def add(%Aggregator.Point{} = point) do
    :telemetry.execute([:datadog, :datastreams, :aggregator, :payloads_in], %{count: 1})
    GenServer.cast(__MODULE__, {:add, point})
  end

  def add(%Aggregator.Offset{} = offset) do
    GenServer.cast(__MODULE__, {:add, offset})
  end

  @doc """
  Sends all stored data to the Datadog agent.

  ## Examples

      iex> :ok = Aggregator.flush()
  """
  @spec flush :: :ok
  def flush do
    Process.send(__MODULE__, :send, [])
  end

  @doc false
  def init([{:enabled?, false} | _rest]), do: :ignore

  def init(_opts) do
    Process.flag(:trap_exit, true)

    {:ok,
     %{
       send_timer: Process.send_after(self(), :send, @send_interval),
       ts_type_current_buckets: %{},
       ts_type_origin_buckets: %{}
     }}
  end

  @doc false
  def handle_cast({:add, %Aggregator.Point{} = point}, state) do
    new_ts_type_current_buckets =
      Aggregator.Bucket.upsert(state.ts_type_current_buckets, point.timestamp, fn bucket ->
        new_groups =
          Aggregator.Group.upsert(bucket.groups, point, fn group ->
            Aggregator.Group.add(group, point)
          end)

        %{bucket | groups: new_groups}
      end)

    origin_timestamp = point.timestamp - point.pathway_latency

    new_ts_type_origin_buckets =
      Aggregator.Bucket.upsert(state.ts_type_origin_buckets, origin_timestamp, fn bucket ->
        new_groups =
          Aggregator.Group.upsert(bucket.groups, point, fn group ->
            Aggregator.Group.add(group, point)
          end)

        %{bucket | groups: new_groups}
      end)

    {:noreply,
     %{
       state
       | ts_type_current_buckets: new_ts_type_current_buckets,
         ts_type_origin_buckets: new_ts_type_origin_buckets
     }}
  end

  def handle_cast({:add, %Aggregator.Offset{} = offset}, state) do
    new_ts_type_current_buckets =
      Aggregator.Bucket.upsert(state.ts_type_current_buckets, offset.timestamp, fn bucket ->
        type_key = if offset.type == :commit, do: :latest_commit_offsets, else: :latest_produce_offsets

        new_offsets = bucket |> Map.get(:type_key, []) |> Aggregator.Offset.upsert(offset)
        Map.put(bucket, type_key, new_offsets)
      end)

    {:noreply, %{state | ts_type_current_buckets: new_ts_type_current_buckets}}
  end

  @doc false
  def handle_info(:send, state) do
    Process.cancel_timer(state.send_timer)

    now = :erlang.system_time(:nanosecond)

    {active_ts_type_current_buckets, past_ts_type_current_buckets} =
      split_with(state.ts_type_current_buckets, fn {_k, v} ->
        Aggregator.Bucket.current?(v, now)
      end)

    {active_ts_type_origin_buckets, past_ts_type_origin_buckets} =
      split_with(state.ts_type_origin_buckets, fn {_k, v} ->
        Aggregator.Bucket.current?(v, now)
      end)

    payload =
      Payload.new()
      |> Payload.add_buckets(past_ts_type_current_buckets, :current)
      |> Payload.add_buckets(past_ts_type_origin_buckets, :origin)

    unless Payload.stats_count(payload) == 0 do
      Task.async(fn ->
        with {:ok, encoded_payload} <- Payload.encode(payload),
             :ok <- Transport.send_pipeline_stats(encoded_payload) do
          {:ok, Payload.stats_count(payload)}
        else
          {:error, reason} -> {:error, reason}
          something -> {:error, something}
        end
      end)
    end

    {:noreply,
     %{
       state
       | send_timer: Process.send_after(self(), :send, @send_interval),
         ts_type_current_buckets: active_ts_type_current_buckets,
         ts_type_origin_buckets: active_ts_type_origin_buckets
     }}
  end

  @doc false
  def handle_info({task_ref, {:ok, count}}, state) when is_reference(task_ref) do
    Logger.debug("Successfully sent metrics to Datadog")
    :telemetry.execute([:datadog, :datastreams, :aggregator, :flushed_payloads], %{count: 1})
    :telemetry.execute([:datadog, :datastreams, :aggregator, :flushed_buckets], %{count: count})
    {:noreply, state}
  end

  @doc false
  def handle_info({task_ref, {:error, error}}, state) when is_reference(task_ref) do
    Logger.error("Error sending metrics to Datadog", error: error)
    :telemetry.execute([:datadog, :datastreams, :aggregator, :flush_errors], %{count: 1})
    {:noreply, state}
  end

  @doc false
  def handle_info(_, state), do: {:noreply, state}

  @doc false
  def terminate(_reason, %{ts_type_current_buckets: %{}, ts_type_origin_buckets: %{}}) do
    Logger.debug("Stopping #{__MODULE__} with an empty state")
  end

  @doc false
  def terminate(_reason, state) do
    payload =
      Payload.new()
      |> Payload.add_buckets(state.ts_type_current_buckets, :current)
      |> Payload.add_buckets(state.ts_type_origin_buckets, :origin)

    with {:ok, encoded_payload} <- Payload.encode(payload),
         :ok <- Transport.send_pipeline_stats(encoded_payload) do
      Logger.debug("Successfully sent metrics to Datadog before termination")
      :telemetry.execute([:datadog, :datastreams, :aggregator, :flushed_payloads], %{count: 1})

      :telemetry.execute([:datadog, :datastreams, :aggregator, :flushed_buckets], %{
        count: Payload.stats_count(payload)
      })
    else
      error ->
        Logger.error("Error sending metrics to Datadog before termination", error: error)
        :telemetry.execute([:datadog, :datastreams, :aggregator, :flush_errors], %{count: 1})
    end
  rescue
    error ->
      Logger.error("Error attempting to sending metrics to Datadog before termination",
        error: error
      )

      :telemetry.execute([:datadog, :datastreams, :aggregator, :flush_errors], %{count: 1})
  end

  # Splits the `map` into two maps according to the given function `fun`.
  # This function was taken from Elixir 1.15 for backwards support with older
  # versions.
  defp split_with(map, fun) when is_map(map) and is_function(fun, 1) do
    iter = :maps.iterator(map)
    next = :maps.next(iter)

    do_split_with(next, [], [], fun)
  end

  defp do_split_with(:none, while_true, while_false, _fun) do
    {:maps.from_list(while_true), :maps.from_list(while_false)}
  end

  defp do_split_with({key, value, iter}, while_true, while_false, fun) do
    if fun.({key, value}) do
      do_split_with(:maps.next(iter), [{key, value} | while_true], while_false, fun)
    else
      do_split_with(:maps.next(iter), while_true, [{key, value} | while_false], fun)
    end
  end
end
