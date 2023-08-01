defmodule Datadog.DataStreams.Aggregator.Bucket do
  @moduledoc false

  alias Datadog.DataStreams.Aggregator

  # 10 seconds in nanoseconds
  @bucket_duration 10 * 1_000 * 1_000 * 1_000

  defstruct groups: %{},
            latest_commit_offsets: [],
            latest_produce_offsets: [],
            start: 0,
            duration: @bucket_duration

  @type t :: %__MODULE__{
          groups: %{non_neg_integer() => Aggregator.Group.t()},
          latest_commit_offsets: [Aggregator.Offset.t()],
          latest_produce_offsets: [Aggregator.Offset.t()],
          start: non_neg_integer(),
          duration: non_neg_integer()
        }

  @spec align_timestamp(non_neg_integer()) :: non_neg_integer()
  defp align_timestamp(timestamp) do
    timestamp - rem(timestamp, @bucket_duration)
  end

  @doc """
  Creates a new aggregator bucket based on the aligned start timestamp.
  """
  @spec new(non_neg_integer()) :: t()
  def new(timestamp) do
    %__MODULE__{start: align_timestamp(timestamp)}
  end

  @doc """
  Checks if the bucket is currently within its active duration.
  """
  @spec current?(t(), non_neg_integer()) :: boolean()
  def current?(%{start: start}, now) do
    start > now + @bucket_duration
  end

  @doc """
  Updates an existing `#{__MODULE__}` that matches the given timestamp,
  or creates a new bucket matching the timestamp given if one can not
  be found.
  """
  @spec upsert(%{required(non_neg_integer()) => t()}, non_neg_integer(), (t() -> t())) :: %{
          required(non_neg_integer()) => t()
        }
  def upsert(buckets, timestamp, fun) do
    timestamp = align_timestamp(timestamp)

    new_bucket =
      buckets
      |> Map.get(timestamp, new(timestamp))
      |> fun.()

    Map.put(buckets, timestamp, new_bucket)
  end
end
