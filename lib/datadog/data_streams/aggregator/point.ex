defmodule Datadog.DataStreams.Aggregator.Point do
  @moduledoc false

  defstruct edge_tags: [],
            hash: 0,
            parent_hash: 0,
            pathway_latency: 0,
            edge_latency: 0,
            timestamp: 0

  @typedoc """
  This represents a _non aggregated_ single point of data from a
  Kafka message. It's used as a function argument here when aggregating
  latency data.
  """
  @type t :: %__MODULE__{
          edge_tags: [String.t()],
          hash: non_neg_integer(),
          parent_hash: non_neg_integer(),
          pathway_latency: non_neg_integer(),
          edge_latency: non_neg_integer(),
          timestamp: non_neg_integer()
        }
end
