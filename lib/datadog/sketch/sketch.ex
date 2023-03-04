defmodule Datadog.Sketch do
  @moduledoc """
  A minimal implementation of the distributed quantile sketch (DDSketch)
  algorithm as implemented in the [`sketches-go`][sg] library. For more
  information, please read the [`sketches-go` README][sg].

  This is a minimal implementation needed to support DataDog data streams.
  Some initial work was taken from the great [`dog_sketch` Elixir library][dd].
  This library includes some DataDog specific work like Protobuf encoding. It's
  worth mentioning that some of this code looks out of place in Elixir. That is
  because it's pulled directly from the [`sketches-go`][sg] library and kept
  similar for ease of debugging and backporting fixes.

  [sg]: sketches-go
  [dd]: https://github.com/moosecodebv/dog_sketch
  """

  alias Datadog.Sketch.IndexMapping

  defstruct [
    index_mapping: nil,
    positive_value_store: nil,
    negative_value_store: nil,
    zero_count: 0
  ]

  @type t :: %__MODULE__{
    index_mapping: IndexMapping.t(),
    positive_value_store: module(),
    negative_value_store: module(),
    zero_count: non_neg_integer()
  }

  @doc """
  Creates a new Sketch.
  """
  @spec new(IndexMapping.t(), module()) :: t()
  def new(index_mapping, store_provider) do
    %__MODULE__{
      index_mapping: index_mapping,
      positive_value_store: store_provider.new(),
      negative_value_store: store_provider.new()
    }
  end

  @doc """
  Creates a new Sketch with separate stores for positive and negative
  values.
  """
  @spec new(IndexMapping.t(), module(), module()) :: t()
  def new(index_mapping, positive_store_provider, negative_store_provider) do
    %__MODULE__{
      index_mapping: index_mapping,
      positive_value_store: positive_store_provider.new(),
      negative_value_store: negative_store_provider.new()
    }
  end
end
