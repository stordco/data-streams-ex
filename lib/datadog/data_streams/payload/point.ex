defmodule Datadog.DataStreams.Payload.Point do
  @moduledoc false

  alias Datadog.Sketch

  defstruct edge_tags: [],
            hash: 0,
            parent_hash: 0,
            pathway_latency: Sketch.new_default(),
            edge_latency: Sketch.new_default(),
            timestamp_type: :current

  @type timestamp :: :current | :origin

  @type t :: %__MODULE__{
          edge_tags: [String.t()],
          hash: non_neg_integer(),
          parent_hash: non_neg_integer(),
          pathway_latency: Sketch.t(),
          edge_latency: Sketch.t(),
          timestamp_type: timestamp()
        }
end

defimpl Msgpax.Packer, for: Datadog.DataStreams.Payload.Point do
  def pack(data) do
    [
      # Service
      [0x87, 0xA7, 0x53, 0x65, 0x72, 0x76, 0x69, 0x63, 0x65],
      # Deprecated field. Always returns an empty string.
      [160, ""],
      # EdgeTags
      [0xA8, 0x45, 0x64, 0x67, 0x65, 0x54, 0x61, 0x67, 0x73],
      Msgpax.Packer.pack(data.edge_tags),
      # Hash
      [0xA4, 0x48, 0x61, 0x73, 0x68],
      Msgpax.Packer.pack(data.hash),
      # ParentHash
      [0xAA, 0x50, 0x61, 0x72, 0x65, 0x6E, 0x74, 0x48, 0x61, 0x73, 0x68],
      Msgpax.Packer.pack(data.parent_hash),
      # PathwayLatency
      [0xAE, 0x50, 0x61, 0x74, 0x68, 0x77, 0x61, 0x79, 0x4C, 0x61, 0x74, 0x65, 0x6E, 0x63, 0x79],
      data.pathway_latency
      |> Datadog.Sketch.to_proto()
      |> Protobuf.encode()
      |> Msgpax.Bin.new()
      |> Msgpax.Packer.pack(),
      # EdgeLatency
      [0xAB, 0x45, 0x64, 0x67, 0x65, 0x4C, 0x61, 0x74, 0x65, 0x6E, 0x63, 0x79],
      data.edge_latency
      |> Datadog.Sketch.to_proto()
      |> Protobuf.encode()
      |> Msgpax.Bin.new()
      |> Msgpax.Packer.pack(),
      # TimestampType
      [0xAD, 0x54, 0x69, 0x6D, 0x65, 0x73, 0x74, 0x61, 0x6D, 0x70, 0x54, 0x79, 0x70, 0x65],
      Msgpax.Packer.pack(to_string(data.timestamp_type))
    ]
  end
end
