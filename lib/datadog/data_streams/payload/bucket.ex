defmodule Datadog.DataStreams.Payload.Bucket do
  @moduledoc false

  alias Datadog.DataStreams.Payload

  # 10 seconds in nanoseconds
  @duration 10 * 1_000_000_000

  defstruct start: 0,
            duration: @duration,
            stats: [],
            backlogs: []

  @type t() :: %__MODULE__{
          start: non_neg_integer(),
          duration: non_neg_integer(),
          stats: [Payload.Point.t()],
          backlogs: [Payload.Backlog.t()]
        }
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
