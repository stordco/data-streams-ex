defmodule Datadog.DataStreams.Payload.Bucket do
  @moduledoc false

  alias Datadog.DataStreams.{Aggregator, Payload}

  # 10 seconds in nanoseconds
  @bucket_duration 10 * 1_000 * 1_000 * 1_000

  defstruct start: 0,
            duration: @bucket_duration,
            stats: [],
            backlogs: []

  @type t() :: %__MODULE__{
          start: non_neg_integer(),
          duration: non_neg_integer(),
          stats: [Payload.Point.t()],
          backlogs: [Payload.Backlog.t()]
        }

  @doc """
  Creates a new payload bucket from an aggregator bucket.
  """
  @spec new(Aggregator.Bucket.t(), Payload.Point.timestamp_type()) :: t()
  def new(%Aggregator.Bucket{} = bucket, timestamp_type) do
    %__MODULE__{
      start: bucket.start,
      duration: bucket.duration,
      stats: bucket.points |> Map.values() |> Enum.map(&Payload.Point.new(&1, timestamp_type))
    }
  end
end

defimpl Msgpax.Packer, for: Datadog.DataStreams.Payload.Bucket do
  def pack(data) do
    [
      # Start
      [0x84, 0xA5, 0x53, 0x74, 0x61, 0x72, 0x74],
      Msgpax.Packer.pack(data.start),
      # Duration
      [0xA8, 0x44, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E],
      Msgpax.Packer.pack(data.duration),
      # Stats
      [0xA5, 0x53, 0x74, 0x61, 0x74, 0x73],
      Msgpax.Packer.pack(data.stats),
      # Backlogs
      [0xA8, 0x42, 0x61, 0x63, 0x6B, 0x6C, 0x6F, 0x67, 0x73],
      Msgpax.Packer.pack(data.backlogs)
    ]
  end
end
