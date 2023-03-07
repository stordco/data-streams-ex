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

  `Datadog.Sketch` also implements the `Enumerable` protocol for easy access to
  data stored. All keys and values will be processed by the `IndexMapping`
  module before being enumerated. It also includes all zero values.

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
  Creates a new Sketch with the default index mapping and store values.
  This equates to using the `IndexMapping.Logarithmic` module with a
  `0.01` relative accuracy and the `Store.Dense` store.

  ## Examples

      iex> %Sketch{} = Sketch.new_default()

  """
  @spec new_default() :: t()
  def new_default() do
    %__MODULE__{
      index_mapping: IndexMapping.Logarithmic.new(0.01),
      positive_value_store: Store.Dense.new(),
      negative_value_store: Store.Dense.new()
    }
  end

  @doc """
  Creates a new Sketch.

  ## Examples

      iex> index_mapping = Sketch.IndexMapping.Logarithmic.new(0.01)
      ...> store = Sketch.Store.Dense.new()
      ...> %Sketch{} = Sketch.new(index_mapping, store)

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

  ## Examples

      iex> index_mapping = Sketch.IndexMapping.Logarithmic.new(0.01)
      ...> positive_store = Sketch.Store.Dense.new()
      ...> negative_store = Sketch.Store.Dense.new()
      ...> %Sketch{} = Sketch.new(index_mapping, positive_store, negative_store)

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

  ## Examples

      iex> %Sketch{} = Sketch.add(Sketch.new_default(), 4293.7)

      iex> %Sketch{} = Sketch.add(Sketch.new_default(), -4592.3)

      iex> %Sketch{} = Sketch.add(Sketch.new_default(), 0.0)

  """
  @spec add(t(), number()) :: t()
  def add(sketch, value) do
    add_with_count(sketch, value, 1.0)
  end

  @doc """
  Adds a bin type to the sketch.

  ## Examples

        iex> %Sketch{} = Sketch.add_bin(Sketch.new_default(), %{index: 100, count: 13.13})

  """
  @spec add_bin(t(), Store.bin()) :: t()
  def add_bin(sketch, %{count: count, index: index}) do
    add_with_count(sketch, index, count)
  end

  @doc """
  Adds multiple bin types to the sketch.

  ## Examples

        iex> %Sketch{} = Sketch.add_bins(Sketch.new_default(), [
        ...>   %{index: 100, count: 13.13},
        ...>   %{index: 20, count: 2342.4}
        ...> ])

  """
  @spec add_bins(t(), [Store.bin()]) :: t()
  def add_bins(sketch, bins) when is_list(bins),
    do: Enum.reduce(bins, sketch, &add_bin(&2, &1))

  @doc """
  Adds a value to the sketch with a float count.

  ## Examples

      iex> %Sketch{} = Sketch.add_with_count(Sketch.new_default(), 4293.7, 294)

      iex> %Sketch{} = Sketch.add_with_count(Sketch.new_default(), -4592.3, 23)

      iex> %Sketch{} = Sketch.add_with_count(Sketch.new_default(), 0.0, 10)

  """
  @spec add_with_count(t(), number(), float()) :: t() | no_return()
  def add_with_count(_sketch, _value, count) when count < 0,
    do: raise(ArgumentError, message: "count cannot be negative")

  def add_with_count(sketch, value, count) when value == 0.0,
    do: %{sketch | zero_count: sketch.zero_count + count}

  def add_with_count(sketch, value, count) when value > 0 do
    %{
      sketch
      | positive_value_store:
          Store.add_with_count(
            sketch.positive_value_store,
            IndexMapping.index(sketch.index_mapping, value),
            count
          )
    }
  end

  def add_with_count(sketch, value, count) when value < 0 do
    %{
      sketch
      | negative_value_store:
          Store.add_with_count(
            sketch.negative_value_store,
            IndexMapping.index(sketch.index_mapping, -value),
            count
          )
    }
  end

  @doc """
  Return the value at the specified quantile.

  ## Examples

      # Validated with golang implementation
      iex> sketch = Sketch.add_bins(Sketch.new_default(), [
      ...>   %{index: 12, count: 423.43},
      ...>   %{index: 244, count: 1238.123},
      ...>   %{index: 124, count: 2184.124}
      ...> ])
      ...> Sketch.get_value_at_quantile(sketch, 0.4)
      125.2248607394614

  """
  @spec get_value_at_quantile(t(), float()) :: float() | nil | no_return()
  def get_value_at_quantile(_sketch, quantile) when quantile < 0 or quantile > 1,
    do: raise(ArgumentError, message: "The quantile must be between 0, and 1.")

  def get_value_at_quantile(sketch, quantile) do
    count = get_count(sketch)

    if count == 0.0 do
      nil
    else
      rank = quantile * (count - 1)
      negative_value_count = Store.total_count(sketch.negative_value_store)

      cond do
        rank < negative_value_count ->
          -IndexMapping.value(
            sketch.index_mapping,
            Store.key_at_rank(sketch.negative_value_store, negative_value_count - 1 - rank)
          )

        rank < sketch.zero_count + negative_value_count ->
          0.0

        true ->
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

  ## Examples

      # Validated with golang implementation (within accuracy)
      iex> sketch = Sketch.add_bins(Sketch.new_default(), [
      ...>   %{index: 12, count: 423.43},
      ...>   %{index: 244, count: 1238.123},
      ...>   %{index: 124, count: 2184.124}
      ...> ])
      ...> Sketch.get_values_at_quantiles(sketch, [0.1, 0.25, 0.5])
      [12.061674179039226, 125.2248607394614, 125.2248607394614]

  """
  @spec get_values_at_quantiles(t(), list(float())) :: list(float() | nil)
  def get_values_at_quantiles(sketch, quantiles) do
    Enum.map(quantiles, fn q -> get_value_at_quantile(sketch, q) end)
  end

  @doc """
  Return the total number of values that have been added to this sketch.

  ## Examples

      iex> sketch = Sketch.add_bins(Sketch.new_default(), [
      ...>   %{index: 12, count: 423.43},
      ...>   %{index: 244, count: 1238.123},
      ...>   %{index: 124, count: 2184.124}
      ...> ])
      ...> Sketch.get_count(sketch)
      3845.6769999999997

  """
  @spec get_count(t()) :: float()
  def get_count(sketch) do
    sketch.zero_count + Store.total_count(sketch.positive_value_store) +
      Store.total_count(sketch.negative_value_store)
  end

  @doc """
  Returns the number of zero values that have been added to this sketch.

  ## Examples

      iex> sketch = Sketch.add_bins(Sketch.new_default(), [
      ...>   %{index: 12, count: 34},
      ...>   %{index: -423, count: 571},
      ...>   %{index: 0, count: 27.1}
      ...> ])
      ...> Sketch.get_zero_count(sketch)
      27.1

  """
  @spec get_zero_count(t()) :: float()
  def get_zero_count(%__MODULE__{zero_count: zero_count}), do: zero_count

  @doc """
  Returns true if no value has been added to this sketch.

  ## Examples

      iex> Sketch.empty?(Sketch.new_default())
      true

      iex> Sketch.new_default()
      ...> |> Sketch.add_with_count(42, 482.23)
      ...> |> Sketch.empty?()
      false

      iex> Sketch.new_default()
      ...> |> Sketch.add_with_count(-75, 157)
      ...> |> Sketch.empty?()
      false

  """
  @spec empty?(t()) :: bool()
  def empty?(%__MODULE__{zero_count: zero_count} = sketch) do
    zero_count == 0.0 and Store.empty?(sketch.positive_value_store) and
      Store.empty?(sketch.negative_value_store)
  end

  @doc """
  Returns the maximum value that has been added to this sketch.

  ## Examples

      iex> sketch = Sketch.add_bins(Sketch.new_default(), [
      ...>   %{index: 12, count: 34},
      ...>   %{index: -423, count: 571},
      ...>   %{index: 0, count: 27.1}
      ...> ])
      ...> Sketch.get_max_value(sketch)
      12.061674179039226

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

  ## Examples

      iex> sketch = Sketch.add_bins(Sketch.new_default(), [
      ...>   %{index: 12, count: 34},
      ...>   %{index: -423, count: 571},
      ...>   %{index: 0, count: 27.1}
      ...> ])
      ...> Sketch.get_min_value(sketch)
      -424.1773628048435

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

  ## Examples

      # Verified with golang implementation (within accuracy)
      iex> sketch = Sketch.add_bins(Sketch.new_default(), [
      ...>   %{index: 12, count: 34.0},
      ...>   %{index: -24, count: 84.0},
      ...>   %{index: 0, count: 2.4}
      ...> ])
      ...> Sketch.get_sum(sketch)
      -1589.8430984284082

  """
  @spec get_sum(t()) :: float()
  def get_sum(sketch) do
    positives =
      Enum.reduce(sketch.positive_value_store, 0.0, fn {index, count}, sum ->
        sum + IndexMapping.value(sketch.index_mapping, index) * count
      end)

    negatives =
      Enum.reduce(sketch.negative_value_store, 0.0, fn {index, count}, sum ->
        sum + -IndexMapping.value(sketch.index_mapping, index) * count
      end)

    positives + negatives
  end

  @doc """
  Returns a Protobuf-able struct for the sketch. Used for sending data to
  Datadog.

  ## Examples

      iex> %Sketch.Protobuf.DDSketch{} = Sketch.to_proto(Sketch.new_default())

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

  ## Examples

        # Verified with golang implementation (within accuracy)
        iex> sketch = Sketch.add_bins(Sketch.new_default(), [
        ...>   %{index: -7, count: 10.0},
        ...>   %{index: 24, count: 20.0},
        ...>   %{index: 3, count: 30.0}
        ...> ])
        ...> sketch = Sketch.reweight(sketch, 2.5)
        ...> Sketch.get_sum(sketch)
        1237.7881696246109

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
