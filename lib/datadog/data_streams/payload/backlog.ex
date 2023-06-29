defmodule Datadog.DataStreams.Payload.Backlog do
  @moduledoc false

  alias Datadog.DataStreams.{Aggregator, Tags}

  defstruct tags: [],
            value: 0

  @type t() :: %__MODULE__{
          tags: Tags.encoded(),
          value: non_neg_integer()
        }

  @doc """
  Creates a new backlog struct from an aggregator offset.
  """
  @spec new(Aggregator.Offset.t()) :: t()
  def new(%Aggregator.Offset{offset: offset, tags: tags}) do
    %__MODULE__{
      tags: tags |> Tags.parse() |> Tags.encode(),
      value: offset
    }
  end
end

defimpl Msgpax.Packer, for: Datadog.DataStreams.Payload.Backlog do
  def pack(data) do
    [
      # Tags
      [0x82, 0xA4, 0x54, 0x61, 0x67, 0x73],
      Msgpax.Packer.pack(data.tags),
      # Value
      [0xA5, 0x56, 0x61, 0x6C, 0x75, 0x65],
      Msgpax.Packer.pack(data.value)
    ]
  end
end
