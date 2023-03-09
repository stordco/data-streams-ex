defmodule Datadog.DataStreams.Pathway do
  @moduledoc """
  A pathway is used to monitor how payloads are sent across different services.

  An example pathway would be:

  ```text
  service A -- edge 1 --> service B -- edge 2 --> service C
  ```

  So it's a bunch of services (we also call them "nodes") connected via edges.
  As the payload is sent around, we save the start time (start of service A),
  and the start time of the previous service. This allows us to measure the
  latency of each edge, as well as the latency from origin of any service.

  See the [data-streams-go][DSG] package for more details.

  [DSG]: https://github.com/DataDog/data-streams-go/blob/main/datastreams/pathway.go
  """

  alias Datadog.DataStreams.{Aggregator, Config}

  @hashable_edge_tags ["event_type", "exchange", "group", "topic", "type"]

  defstruct hash: 0,
            pathway_start: 0,
            edge_start: 0

  @type t :: %__MODULE__{
          hash: non_neg_integer(),
          pathway_start: non_neg_integer(),
          edge_start: non_neg_integer()
        }

  @doc """
  Merges multiple pathways into one. The current implementation samples
  one resulting pathway. A future implementation could be more clever
  and actually merge the pathways.
  """
  @spec merge(list(t())) :: t()
  def merge([]), do: %__MODULE__{}
  def merge(pathways) when is_list(pathways), do: Enum.random(pathways)

  @doc """
  Hashes all data for a pathway.

  ## Examples

      iex> Pathway.node_hash("service-1", "env", "d:1", [])
      2071821778175304604

      iex> # Invalid edge tag
      ...> Pathway.node_hash("service-1", "env", "d:1", ["edge-1"])
      2071821778175304604

      iex> Pathway.node_hash("service-1", "env", "d:1", ["type:kafka"])
      9272613839978655432

  """
  @spec node_hash(String.t(), String.t(), String.t(), list(String.t())) :: non_neg_integer()
  def node_hash(service, env, primary_tag, edge_tags \\ []) do
    edge_tags =
      edge_tags
      |> Enum.filter(fn tag ->
        case String.split(tag, ":") do
          [key, _value] when key in @hashable_edge_tags -> true
          _ -> false
        end
      end)
      |> Enum.sort()

    ([service, env, primary_tag] ++ edge_tags)
    |> Enum.join("")
    |> FNV.FNV1.hash64()
  end

  @doc """
  Hashes together a node and parent hash

  ## Examples

      iex> Pathway.pathway_hash(0, 0)
      9808874869469701221

      iex> Pathway.pathway_hash(2071821778175304604, 0)
      17210443572488294574

      iex> Pathway.pathway_hash(0, 2071821778175304604)
      12425197808660046030

      iex> Pathway.pathway_hash(2071821778175304604, 17210443572488294574)
      2003974475228685984

  """
  @spec pathway_hash(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def pathway_hash(node_hash, parent_hash) do
    FNV.FNV1.hash64(binary_encode_unsigned(node_hash) <> binary_encode_unsigned(parent_hash))
  end

  defp binary_encode_unsigned(int) do
    bin_list =
      int
      |> :binary.encode_unsigned(:little)
      |> :binary.bin_to_list()

    (bin_list ++ [0, 0, 0, 0, 0, 0, 0, 0])
    |> Enum.slice(0..7)
    |> :binary.list_to_bin()
  end

  @doc """
  Creates a new pathway struct.
  """
  @spec new_pathway(list(String.t())) :: t()
  def new_pathway(edge_tags) do
    :nanosecond
    |> :erlang.system_time()
    |> new_pathway(edge_tags)
  end

  @doc """
  Creates a new pathway at a given time in unix epoch nanoseconds.
  """
  @spec new_pathway(non_neg_integer(), list(String.t())) :: t()
  def new_pathway(now, edge_tags) do
    set_checkpoint(
      %__MODULE__{
        hash: 0,
        pathway_start: now,
        edge_start: now
      },
      now,
      edge_tags
    )
  end

  @doc """
  Sets a checkpoint on the pathway.
  """
  @spec set_checkpoint(t(), list(String.t())) :: t()
  def set_checkpoint(pathway, edge_tags) do
    set_checkpoint(pathway, :erlang.system_time(:nanosecond), edge_tags)
  end

  @doc """
  Sets a checkpoint on the pathway at the given time in unix epoch nanoseconds.
  """
  @spec set_checkpoint(t(), non_neg_integer(), list(String.t())) :: t()
  def set_checkpoint(pathway, now, edge_tags) do
    node_hash =
      node_hash(
        Config.service(),
        Config.env(),
        Config.primary_tag(),
        edge_tags
      )

    child = %__MODULE__{
      hash: pathway_hash(node_hash, pathway.hash),
      pathway_start: pathway.pathway_start,
      edge_start: now
    }

    Aggregator.add(%Aggregator.Point{
      edge_tags: edge_tags,
      parent_hash: pathway.hash,
      hash: child.hash,
      timestamp: now,
      pathway_latency: now - pathway.pathway_start,
      edge_latency: now - pathway.edge_start
    })

    child
  end
end
