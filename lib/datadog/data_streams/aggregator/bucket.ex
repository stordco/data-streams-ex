defmodule Datadog.DataStreams.Aggregator.Bucket do
  @moduledoc false

  alias Datadog.DataStreams.Aggregator

  # 10 seconds in nanoseconds
  @bucket_duration 10 * 1_000 * 1_000 * 1_000

  defstruct points: %{},
            latest_commit_offsets: %{},
            latest_produce_offsets: %{},
            start: 0,
            duration: @bucket_duration

  @type t :: %__MODULE__{
          points: %{non_neg_integer() => Aggregator.Group.t()},
          latest_commit_offsets: %{non_neg_integer() => non_neg_integer()},
          latest_produce_offsets: %{partition_key() => non_neg_integer()},
          start: non_neg_integer(),
          duration: non_neg_integer()
        }

  @type partition_key :: %{
          partition: non_neg_integer(),
          topic: String.t()
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
    Map.update(buckets, timestamp, new(timestamp), fun)
  end
end