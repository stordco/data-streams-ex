defmodule Datadog.DataStreams.Payload do
  @moduledoc """
  Encoding logic for a payload. This is the top level struct we send
  to Datadog. It wraps all other information. These are primarily sent via
  [MessagePack][mp], although uses [Protobuf][pb] encoded binary for latency
  records.

  [mp]: https://msgpack.org/index.html
  [pb]: https://protobuf.dev/
  """

  alias Datadog.DataStreams.{Aggregator, Config, Payload}

  defstruct env: "",
            service: "",
            primary_tag: "",
            stats: [],
            tracer_version: "1.0.0",
            lang: "Elixir"

  @type t() :: %__MODULE__{
          env: String.t(),
          service: String.t(),
          primary_tag: String.t(),
          stats: [Payload.Bucket.t()],
          tracer_version: String.t(),
          lang: String.t()
        }

  @doc """
  Creates a new payload with the environment, service, and primary_tag
  filled in from the `Datadog.DataStreams.Config` module.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      env: Config.env(),
      service: Config.service(),
      primary_tag: Config.primary_tag()
    }
  end

  @doc """
  Adds a map of buckets. This is the format the the aggregator uses internally.
  We throw out the hash and just keep the buckets.
  """
  @spec add_buckets(
          t(),
          %{required(non_neg_integer()) => Aggregator.Bucket.t()},
          Payload.Point.timestamp_type()
        ) :: t()
  def add_buckets(payload, buckets, timestamp_type) do
    buckets
    |> Map.values()
    |> Enum.reduce(payload, &add_bucket(&2, &1, timestamp_type))
  end

  @doc """
  Adds an aggregator bucket to the payload.
  """
  @spec add_bucket(t(), Aggregator.Bucket.t(), Payload.Point.timestamp_type()) :: t()
  def add_bucket(%__MODULE__{} = payload, %Aggregator.Bucket{} = bucket, timestamp_type) do
    %{payload | stats: payload.stats ++ [Payload.Bucket.new(bucket, timestamp_type)]}
  end

  @doc """
  Returns how many stats are in the payload.
  """
  @spec stats_count(t()) :: non_neg_integer()
  def stats_count(payload) do
    length(payload.stats)
  end

  @doc """
  Encodes the payload via MessagePack.
  """
  @spec encode(t()) :: {:ok, binary()} | {:error, any()}
  def encode(payload) do
    Msgpax.pack(payload, iodata: false)
  end
end

defimpl Msgpax.Packer, for: Datadog.DataStreams.Payload do
  def pack(data) do
    [
      # Env
      [0x86, 0xA3, 0x45, 0x6E, 0x76],
      Msgpax.Packer.pack(data.env),
      # Service
      [0xA7, 0x53, 0x65, 0x72, 0x76, 0x69, 0x63, 0x65],
      Msgpax.Packer.pack(data.service),
      # PrimaryTag
      [0xAA, 0x50, 0x72, 0x69, 0x6D, 0x61, 0x72, 0x79, 0x54, 0x61, 0x67],
      Msgpax.Packer.pack(data.primary_tag),
      # Stats
      [0xA5, 0x53, 0x74, 0x61, 0x74, 0x73],
      Msgpax.Packer.pack(data.stats),
      # TracerVersion
      [0xAD, 0x54, 0x72, 0x61, 0x63, 0x65, 0x72, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E],
      Msgpax.Packer.pack(data.tracer_version),
      # Lang
      [0xA4, 0x4C, 0x61, 0x6E, 0x67],
      Msgpax.Packer.pack(data.lang)
    ]
  end
end
