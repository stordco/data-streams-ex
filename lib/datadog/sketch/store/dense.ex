defmodule Datadog.Sketch.Store.Dense do
  @moduledoc """
  The Dense store is a dynamically growing contiguous (non-sparse) store. The
  number of bins are bound only by the size of the `:array` that can be allocated.
  """

  @behaviour Datadog.Sketch.Store

  alias Datadog.Sketch.Store

  @array_length_overhead 64
  @array_length_growth_increment 0.1

  defstruct bins: :array.new(0, [{:fixed, true}, {:default, 0}]),
            count: 0.0,
            offset: 0,
            # Max 32, bit integer Erlang supports. Forces a resize when adding
            # the first number.
            min_index: 134_217_728,
            max_index: -134_217_729

  @type t :: %__MODULE__{
          bins: :array.array(),
          count: float(),
          offset: integer(),
          min_index: integer(),
          max_index: integer()
        }

  @doc """
  Creates a new dense store.

  ## Examples

        iex> Dense.new()
        %Dense{}

  """
  @spec new :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Adds a number to the store.

  ## Examples

        iex> %Dense{} = Dense.add(Dense.new(), 100)

  """
  @impl Datadog.Sketch.Store
  @spec add(t(), integer()) :: t()
  def add(store, index) do
    add_with_count(store, index, 1.0)
  end

  @doc """
  Adds a bin type to the store.

  ## Examples

        iex> %Dense{} = Dense.add_bin(Dense.new(), %{index: 100, count: 13.13})

  """
  @impl Datadog.Sketch.Store
  @spec add_bin(t(), Store.bin()) :: t()
  def add_bin(store, %{count: 0.0}), do: store

  def add_bin(store, %{count: count, index: index}) do
    add_with_count(store, index, count)
  end

  @doc """
  Adds multiple bin types to the store.

  ## Examples

        iex> %Dense{} = Dense.add_bins(Dense.new(), [
        ...>   %{index: 100, count: 13.13},
        ...>   %{index: 20, count: 2342.4}
        ...> ])

  """
  @impl Datadog.Sketch.Store
  @spec add_bins(t(), [Store.bin()]) :: t()
  def add_bins(store, bins) when is_list(bins),
    do: Enum.reduce(bins, store, &add_bin(&2, &1))

  @doc """
  Adds a number to the store `count` number of times.

  ## Examples

        iex> %Dense{} = Dense.add_with_count(Dense.new(), 100, 13.13)

        iex> %Dense{} = Dense.add_with_count(Dense.new(), 987, 8.3e12)

  """
  @impl Datadog.Sketch.Store
  @spec add_with_count(t(), integer(), float()) :: t()
  def add_with_count(store, _index, 0), do: store

  def add_with_count(store, index, count) do
    {store, array_index} = normalize(store, index)

    current_value = safe_get(store.bins, array_index)
    new_bins = :array.set(array_index, current_value + count, store.bins)

    %{store | bins: new_bins, count: store.count + count}
  end

  @spec safe_get(:array.array(), integer()) :: integer()
  defp safe_get(array, index) do
    :array.get(index, array)
  rescue
    ArgumentError -> 0
  end

  @spec normalize(t(), integer()) :: {t(), integer()}
  defp normalize(store, index) do
    if index < store.min_index or index > store.max_index do
      store = extend_range(store, index, index)
      {store, index - store.offset}
    else
      {store, index - store.offset}
    end
  end

  @spec get_new_length(integer(), integer()) :: integer()
  defp get_new_length(new_min_index, new_max_index) do
    desired_length = new_max_index - new_min_index + 1

    round(
      ((desired_length + @array_length_overhead - 1) / @array_length_growth_increment + 1) *
        @array_length_growth_increment
    )
  end

  @spec extend_range(t(), integer(), integer()) :: t()
  defp extend_range(store, new_min_index, new_max_index) do
    new_min_index = min(new_min_index, store.min_index)
    new_max_index = max(new_max_index, store.max_index)

    cond do
      empty?(store) ->
        initial_length = get_new_length(new_min_index, new_max_index)

        store = %{
          store
          | bins: :array.new(initial_length, [{:fixed, true}, {:default, 0}]),
            offset: new_min_index,
            min_index: new_min_index,
            max_index: new_max_index
        }

        adjust(store, new_min_index, new_max_index)

      new_min_index >= store.offset and new_max_index < store.offset + :array.size(store.bins) ->
        %{store | min_index: new_min_index, max_index: new_max_index}

      true ->
        # To avoid shifting too often when nearing the capacity of the array
        # we may grow it before we actually reach the capacity
        new_length = get_new_length(new_min_index, new_max_index)

        if new_length > :array.size(store.bins) do
          store = %{store | bins: :array.resize(new_length, store.bins)}
          adjust(store, new_min_index, new_max_index)
        else
          adjust(store, new_min_index, new_max_index)
        end
    end
  end

  @spec adjust(t(), integer(), integer()) :: t()
  defp adjust(store, new_min_index, new_max_index) do
    center_counts(store, new_min_index, new_max_index)
  end

  @spec center_counts(t(), integer(), integer()) :: t()
  defp center_counts(store, new_min_index, new_max_index) do
    mid_index = new_min_index + div(new_max_index - new_min_index + 1, 2)
    store = shift_counts(store, store.offset + div(:array.size(store.bins), 2) - mid_index)
    %{store | min_index: new_min_index, max_index: new_max_index}
  end

  @spec shift_counts(t(), integer()) :: t()
  defp shift_counts(store, shift) do
    new_array =
      store.bins
      |> :array.size()
      |> :array.new([{:fixed, true}, {:default, 0}])

    new_array =
      store.bins
      |> :array.sparse_to_orddict()
      |> Enum.reduce(new_array, fn {k, v}, new_array ->
        :array.set(k + shift, v, new_array)
      end)

    %{store | bins: new_array, offset: store.offset - shift}
  end

  @doc """
  Checks if the store has any information in it.

  ## Examples

        iex> store = Dense.new()
        ...> Dense.empty?(store)
        true

        iex> store = Dense.add(Dense.new(), 754)
        ...> Dense.empty?(store)
        false

  """
  @impl Datadog.Sketch.Store
  @spec empty?(t()) :: bool()
  def empty?(%{count: 0.0}), do: true
  def empty?(_store), do: false

  @doc """
  Returns the total amount of counts stored.

  ## Examples

        iex> store = Dense.new()
        ...> Dense.total_count(store)
        0.0

        iex> store = Dense.add(Dense.new(), 754)
        ...> Dense.total_count(store)
        1.0

        iex> store = Dense.add_with_count(Dense.new(), 754, 42.42)
        ...> Dense.total_count(store)
        42.42

        # Verified against golang implementation
        iex> store = Dense.add_bins(Dense.new(), [
        ...>   %{index: 4, count: 12.48},
        ...>   %{index: 65, count: 12.48},
        ...>   %{index: 37, count: 847.4}
        ...> ])
        ...> Dense.total_count(store)
        872.36

  """
  @impl Datadog.Sketch.Store
  @spec total_count(t()) :: float()
  def total_count(%{count: count}), do: count

  @doc """
  Returns the minimum index of the store.

  ## Examples

        iex> store = Dense.new()
        ...> Dense.min_index(store)
        0

        # Verified against golang implementation
        iex> store = Dense.add_bins(Dense.new(), [
        ...>   %{index: 4, count: 12.48},
        ...>   %{index: 65, count: 12.48},
        ...>   %{index: 37, count: 847.4}
        ...> ])
        ...> Dense.min_index(store)
        4

  """
  @impl Datadog.Sketch.Store
  @spec min_index(t()) :: integer()
  def min_index(%{count: 0.0}), do: 0
  def min_index(%{min_index: min_index}), do: min_index

  @doc """
  Returns the maximum index of the store.

  ## Examples

        iex> store = Dense.new()
        ...> Dense.max_index(store)
        0

        iex> store = Dense.add(Dense.new(), 128)
        ...> Dense.max_index(store)
        128

        # Verified against golang implementation
        iex> store = Dense.add_bins(Dense.new(), [
        ...>   %{index: 4, count: 12.48},
        ...>   %{index: 65, count: 12.48},
        ...>   %{index: 37, count: 847.4}
        ...> ])
        ...> Dense.max_index(store)
        65

  """
  @impl Datadog.Sketch.Store
  @spec max_index(t()) :: integer()
  def max_index(%{count: 0.0}), do: 0
  def max_index(%{max_index: max_index}), do: max_index

  @doc """
  Return the key for the value at rank.

  ## Examples

        # Matches the golang implementation when no data is present.
        iex> store = Dense.new()
        ...> Dense.key_at_rank(store, 0.0)
        -134_217_729

        # Verified matching to golang implementation
        iex> store = Dense.add(Dense.new(), 128)
        ...> Dense.key_at_rank(store, 0.0)
        128

        # Verified matching to golang implementation
        iex> store = Dense.add_bins(Dense.new(), [
        ...>   %{index: 12, count: 423.43},
        ...>   %{index: 244, count: 1238.123},
        ...>   %{index: 124, count: 2184.124}
        ...> ])
        ...> Dense.key_at_rank(store, 64.0)
        12

  """
  @impl Datadog.Sketch.Store
  @spec key_at_rank(t(), float()) :: integer()
  def key_at_rank(store, rank) when rank < 0.0,
    do: key_at_rank(store, 0.0)

  def key_at_rank(store, rank) do
    {step, result} =
      store.bins
      |> :array.sparse_to_orddict()
      |> Enum.reduce_while({:not_end, 0.0}, fn {i, b}, {step, n} ->
        n = n + b

        if n > rank do
          {:halt, {:end, i + store.offset}}
        else
          {:cont, {step, n}}
        end
      end)

    case step do
      :end -> result
      :not_end -> store.max_index
    end
  end

  @doc """
  Returns a struct for Protobuf encoding. Used for sending data to
  Datadog.

  ## Examples

        # Verified matching to golang implementation
        iex> store = Dense.add(Dense.new(), 4)
        ...> Dense.to_proto(store)
        %Datadog.Sketch.Protobuf.Store{
          binCounts: [],
          contiguousBinCounts: [1.0],
          contiguousBinIndexOffset: 4
        }

        # Verified matching to golang implementation
        iex> store = Dense.add_bins(Dense.new(), [
        ...>   %{index: 4, count: 12.48},
        ...>   %{index: 65, count: 12.48},
        ...>   %{index: 37, count: 847.4}
        ...> ])
        ...> Dense.to_proto(store)
        %Datadog.Sketch.Protobuf.Store{
          binCounts: [],
          contiguousBinCounts: [12.48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 847.4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12.48],
          contiguousBinIndexOffset: 4
        }

  """
  @impl Datadog.Sketch.Store
  @spec to_proto(t()) :: Datadog.Sketch.Protobuf.Store.t()
  def to_proto(%{count: 0.0}), do: %Datadog.Sketch.Protobuf.Store{contiguousBinCounts: nil}

  def to_proto(store) do
    new_length = store.max_index - store.min_index + 1
    new_array = :array.new(new_length, [{:fixed, true}, {:default, 0}])

    new_array =
      store.bins
      |> :array.sparse_to_orddict()
      |> Enum.reduce(new_array, fn {k, v}, new_array ->
        :array.set(k + store.offset - store.min_index, v, new_array)
      end)

    %Datadog.Sketch.Protobuf.Store{
      contiguousBinCounts: :array.to_list(new_array),
      contiguousBinIndexOffset: store.min_index
    }
  end

  @doc """
  Maps over all values and multiplies by the given weight.

  ## Examples

        # Verified matching to golang implementation
        iex> store = Dense.add_bins(Dense.new(), [
        ...>   %{index: 4, count: 10.0},
        ...>   %{index: 2, count: 20.0},
        ...>   %{index: 6, count: 30.0}
        ...> ])
        ...> store = Dense.reweight(store, 2)
        ...> Dense.total_count(store)
        120.0

  """
  @impl Datadog.Sketch.Store
  @spec reweight(t(), float()) :: t()
  def reweight(store, weight) do
    new_bins = :array.sparse_map(fn _i, v -> v * weight end, store.bins)
    %{store | bins: new_bins, count: store.count * weight}
  end
end

defimpl Enumerable, for: Datadog.Sketch.Store.Dense do
  def count(store) do
    length =
      store.bins
      |> :array.sparse_to_orddict()
      |> length()

    {:ok, length}
  end

  def member?(_store, _value), do: {:error, __MODULE__}
  def slice(_store), do: {:error, __MODULE__}

  def reduce(store, acc, fun) do
    store.bins
    |> :array.sparse_to_orddict()
    |> Enum.map(fn {k, v} -> {k + store.offset, v} end)
    |> Enumerable.List.reduce(acc, fun)
  end
end
