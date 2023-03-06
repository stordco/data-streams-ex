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

  [sg]: https://github.com/DataDog/sketches-go
  [dd]: https://github.com/moosecodebv/dog_sketch
  """

  alias Datadog.Sketch.{IndexMapping, Protobuf, Store}

  defstruct index_mapping: nil,
            positive_value_store: nil,
            negative_value_store: nil,
            zero_count: 0.0

  @type t :: %__MODULE__{
          index_mapping: IndexMapping.t(),
          positive_value_store: Store.t(),
          negative_value_store: Store.t(),
          zero_count: float()
        }

  @doc """
  Creates a new Sketch.
  """
  @spec new(IndexMapping.t(), Store.t()) :: t()
  def new(index_mapping, store) do
    %__MODULE__{
      index_mapping: index_mapping,
      positive_value_store: store,
      negative_value_store: store
    }
  end

  @doc """
  Creates a new Sketch with separate stores for positive and negative
  values.
  """
  @spec new(IndexMapping.t(), Store.t(), Store.t()) :: t()
  def new(index_mapping, positive_store, negative_store) do
    %__MODULE__{
      index_mapping: index_mapping,
      positive_value_store: positive_store,
      negative_value_store: negative_store
    }
  end

  @doc """
  Adds a value to the sketch.
  """
  @spec add(t(), float()) :: t()
  def add(sketch, value) do
    add_with_count(sketch, value, 1.0)
  end

  @doc """
  Adds a value to the sketch with a float count.
  """
  @spec add_with_count(t(), float(), float()) :: t() | no_return()
  def add_with_count(_sketch, _value, count) when count < 0,
    do: raise(ArgumentError, message: "count cannot be negative")

  def add_with_count(sketch, value, count) do
    min_indexable_value = IndexMapping.min_indexable_value(sketch.index_mapping)
    max_indexable_value = IndexMapping.max_indexable_value(sketch.index_mapping)

    cond do
      value > min_indexable_value and value > max_indexable_value ->
        raise ArgumentError,
          message: "input value is too high and cannot be tracked by the sketch"

      value > min_indexable_value ->
        %{
          sketch
          | positive_value_store:
              Store.add_with_count(
                sketch.positive_value_store,
                IndexMapping.index(sketch.index_mapping, value),
                count
              )
        }

      value < -min_indexable_value and value < -max_indexable_value ->
        raise ArgumentError, message: "input value is too low and cannot be tracked by the sketch"

      value < -min_indexable_value ->
        %{
          sketch
          | negative_value_store:
              Store.add_with_count(
                sketch.negative_value_store,
                IndexMapping.index(sketch.index_mapping, -value),
                count
              )
        }

      true ->
        %{sketch | zero_count: sketch.zero_count + count}
    end
  end

  @doc """
  Return the value at the specified quantile.
  """
  @spec get_value_at_quantile(t(), float()) :: float() | nil | no_return()
  def get_value_at_quantile(_sketch, quantile) when quantile < 0 or quantile > 1,
    do: raise(ArgumentError, message: "The quantile must be between 0 and 1.")

  def get_value_at_quantile(sketch, quantile) do
    if empty?(sketch) do
      nil
    else
      count = get_count(sketch)
      rank = quantile * (count - 1)
      negative_value_count = Store.total_count(sketch.negative_value_store)

      cond do
        rank < negative_value_count ->
          -IndexMapping.value(
            sketch.index_mapping,
            Store.key_at_rank(sketch.negative_value_store, negative_value_count - 1 - rank)
          )

        rank < sketch.zero_count + negative_value_count ->
          0

          IndexMapping.value(
            sketch.index_mapping,
            Store.key_at_rank(
              sketch.positive_value_store,
              rank - sketch.zero_count - negative_value_count
            )
          )
      end
    end
  end

  @doc """
  Return the values at the respective specified quantiles.
  """
  @spec get_values_at_quantiles(t(), list(float())) :: list(float() | nil)
  def get_values_at_quantiles(sketch, quantiles) do
    Enum.map(quantiles, fn q -> get_value_at_quantile(sketch, q) end)
  end

  @doc """
  Return the total number of values that have been added to this sketch.
  """
  @spec get_count(t()) :: float()
  def get_count(sketch) do
    sketch.zero_count + Store.total_count(sketch.positive_value_store) +
      Store.total_count(sketch.negative_value_store)
  end

  @doc """
  Returns the number of zero values that have been added to this sketch.

  Note: values that are very small (lower than `min_indexable_value` if
  positive, or higher than `-min_indexable_value` if negative) are also
  mapped to the zero bucket.
  """
  @spec get_zero_count(t()) :: float()
  def get_zero_count(%__MODULE__{zero_count: zero_count}), do: zero_count

  @doc """
  Returns true if no value has been added to this sketch.
  """
  @spec empty?(t()) :: bool()
  def empty?(%__MODULE__{zero_count: zero_count} = sketch) do
    zero_count == 0.0 and Store.empty?(sketch.positive_value_store) and
      Store.empty?(sketch.negative_value_store)
  end

  @doc """
  Returns the maximum value that has been added to this sketch.
  """
  @spec get_max_value(t()) :: float()
  def get_max_value(sketch) do
    cond do
      not Store.empty?(sketch.positive_value_store) ->
        max_index = Store.max_index(sketch.positive_value_store)
        IndexMapping.value(sketch.index_mapping, max_index)

      sketch.zero_count > 0 ->
        0.0

      true ->
        min_index = Store.min_index(sketch.negative_value_store)
        -IndexMapping.value(sketch.index_mapping, min_index)
    end
  end

  @doc """
  Returns the minimum value that has been added to this sketch.
  """
  @spec get_min_value(t()) :: float()
  def get_min_value(sketch) do
    cond do
      not Store.empty?(sketch.negative_value_store) ->
        max_index = Store.max_index(sketch.negative_value_store)
        -IndexMapping.value(sketch.index_mapping, max_index)

      sketch.zero_count > 0 ->
        0.0

      true ->
        min_index = Store.min_index(sketch.positive_value_store)
        IndexMapping.value(sketch.index_mapping, min_index)
    end
  end

  @doc """
  Returns an approximation of the sum of the values that have been added
  to the sketch. If the values that have been added to the sketch all
  have the same sign, the approximation error has the relative accuracy
  guarantees of the mapping used for this sketch.
  """
  @spec get_sum(t()) :: float()
  def get_sum(sketch) do
    get_sum_from_store(sketch.positive_value_store) +
      get_sum_from_store(sketch.negative_value_store)
  end

  defp get_sum_from_store(store) do
    Enum.reduce(store, 0.0, fn {value, count}, sum ->
      sum + value * count
    end)
  end

  @doc """
  Returns the `Datadog.Sketch.Store` instance for positive values.
  """
  @spec get_positive_value_store(t()) :: t()
  def get_positive_value_store(%__MODULE__{positive_value_store: positive_value_store}),
    do: positive_value_store

  @doc """
  Returns the `Datadog.Sketch.Store` instance for negative values.
  """
  @spec get_negative_value_store(t()) :: t()
  def get_negative_value_store(%__MODULE__{negative_value_store: negative_value_store}),
    do: negative_value_store

  @doc """
  Returns a Protobuf-able struct for the sketch. Used for sending data to
  Datadog.
  """
  @spec to_proto(t()) :: struct()
  def to_proto(sketch) do
    %Protobuf.DDSketch{
      mapping: IndexMapping.to_proto(sketch.index_mapping),
      positiveValues: Store.to_proto(sketch.positive_value_store),
      negativeValues: Store.to_proto(sketch.negative_value_store),
      zeroCount: sketch.zero_count
    }
  end

  @doc """
  Reweight multiples all values from the sketch by `weight`, but keeps
  the same global distribution. `weight` has to be strictly greater
  than zero.
  """
  @spec reweight(t(), float()) :: t() | no_return()
  def reweight(_sketch, weight) when weight <= 0,
    do: raise(ArgumentError, message: "can't reweight by a negative factor")

  def reweight(sketch, 0.0), do: sketch

  def reweight(sketch, weight) do
    %{
      sketch
      | positive_value_store: Store.reweight(sketch.positive_value_store, weight),
        negative_value_store: Store.reweight(sketch.negative_value_store, weight),
        zero_count: sketch.zero_count * weight
    }
  end
end
