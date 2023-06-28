defmodule Datadog.DataStreams.Aggregator.Offset do
  @moduledoc false

  defstruct offset: 0,
            timestamp: 0,
            type: :commit,
            tags: %{}

  @type type :: :commit | :produce

  @type t :: %__MODULE__{
          offset: integer(),
          timestamp: non_neg_integer(),
          type: type(),
          tags: %{String.t() => any()}
        }

  @doc """
  Creates a new offset map with the given offset and what ever options
  given.
  """
  @spec new(type(), integer(), non_neg_integer(), Keyword.t()) :: t()
  def new(type, offset, timestamp, opts \\ []) do
    %__MODULE__{
      offset: offset,
      timestamp: timestamp,
      type: type,
      tags: Map.new(opts)
    }
  end

  @doc """
  Updates an existing `#{__MODULE__}` where all properties except the
  `offset` match. If no matching one is found, we create a new one.
  """
  @spec upsert([t()], t()) :: [t()]
  def upsert(offsets, %{tags: upsert_tags} = upsert_offset) do
    matching_index =
      Enum.find(offsets, fn %{tags: tags} ->
        match?(^tags, upsert_tags)
      end)

    if is_nil(matching_index) do
      offsets ++ [upsert_offset]
    else
      List.replace_at(offsets, matching_index, upsert_offset)
    end
  end
end
