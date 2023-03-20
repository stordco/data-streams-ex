defmodule Datadog.DataStreams.Payload.Backlog do
  @moduledoc false

  alias Datadog.DataStreams.Tags

  defstruct tags: [],
            value: 0

  @type t() :: %__MODULE__{
          tags: Tags.encoded(),
          value: non_neg_integer()
        }
end

defimpl Msgpax.Packer, for: Datadog.DataStreams.Payload.Backlog do
  def pack(_data) do
    []
  end
end
