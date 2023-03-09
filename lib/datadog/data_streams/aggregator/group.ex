defmodule Datadog.DataStreams.Aggregator.Group do
  @moduledoc false

  alias Datadog.Sketch
  alias Datadog.DataStreams.Aggregator

  defstruct edge_tags: [],
            hash: 0,
            parent_hash: 0,
            pathway_latency: Sketch.new_default(),
            edge_latency: Sketch.new_default()

  @type t :: %__MODULE__{
          edge_tags: [String.t()],
          hash: non_neg_integer(),
          parent_hash: non_neg_integer(),
          pathway_latency: map(),
          edge_latency: map()
        }

  @doc """
  Creates a new aggregate stats group based on the information from a given
  point.
  """
  @spec new(Aggregator.Point.t()) :: t()
  def new(%Aggregator.Point{edge_tags: edge_tags, parent_hash: parent_hash, hash: hash}) do
    %__MODULE__{
      edge_tags: edge_tags,
      parent_hash: parent_hash,
      hash: hash
    }
  end

  @doc """
  Adds latency metrics to a group from a given point.
  """
  @spec add(t(), Aggregator.Point.t()) :: t()
  def add(group, %Aggregator.Point{pathway_latency: pathway_latency, edge_latency: edge_latency}) do
    normalized_pathway_latency = max(pathway_latency / 1_000_000_000, 0)
    normalized_edge_latency = max(edge_latency / 1_000_000_000, 0)

    %{
      group
      | pathway_latency: Sketch.add(group.pathway_latency, normalized_pathway_latency),
        edge_latency: Sketch.add(group.edge_latency, normalized_edge_latency)
    }
  end

  @doc """
  Updates an existing `#{__MODULE__}` with latency data, or creates a new
  `#{__MODULE__}` if one can not be found.
  """
  @spec upsert(%{required(non_neg_integer()) => t()}, Aggregator.Point.t(), (t() -> t())) :: %{
          required(non_neg_integer()) => t()
        }
  def upsert(groups, point, fun) do
    Map.update(groups, point.hash, new(point), fun)
  end
end
