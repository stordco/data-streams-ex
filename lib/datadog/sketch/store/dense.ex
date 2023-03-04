defmodule Datadog.Sketch.Store.Dense do
  @moduledoc """
  The Dense store is a dynamically growing contiguous (non-sparse) store. The
  number of bins are bound only by the size of the :array that can be allocated.
  """

  alias Datadog.Sketch.Store

  defstruct bins: :array.new(0, [{:fixed, true}, {:default, 0}]),
            count: 0.0,
            offset: 0,
            min_index: 0,
            max_index: 0

  @type t :: %__MODULE__{
          bins: :array.array(),
          count: float(),
          offset: integer(),
          min_index: integer(),
          max_index: integer()
        }

  @behaviour Datadog.Sketch.Store

  @array_length_overhead 128
  @array_length_growth_increment 0.1

  @doc """
  Creates a new dense store.
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{
      bins: :array.new(0, [{:fixed, true}, {:default, 0}]),
      count: 0.0,
      offset: 0,
      min_index: 0,
      max_index: 0
    }
  end

  @impl true
  @spec add(t(), integer()) :: t()
  def add(store, index) do
    add_with_count(store, index, 1.0)
  end

  @impl true
  @spec add_bin(t(), Store.bin()) :: t()
  def add_bin(store, %{count: 0.0}), do: store

  def add_bin(store, %{count: count, index: index}) do
    add_with_count(store, index, count)
  end

  @impl true
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

    ceil(
      ((desired_length + @array_length_overhead - 1) / @array_length_growth_increment + 1) *
        @array_length_growth_increment
    )
  end

  @spec extend_range(t(), integer(), integer()) :: t()
  defp extend_range(store, new_min_index, new_max_index) do
    new_min_index = min(new_min_index, store.min_index)
    new_max_index = max(new_max_index, store.max_index)

    cond do
      :array.size(store.bins) == 0 ->
        initial_length = get_new_length(new_min_index, new_max_index)

        store = %{
          store
          | bins: :array.new(initial_length),
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
    mid_index = new_min_index + (new_max_index - new_min_index + 1) / 2
    store = shift_counts(store, round(store.offset + :array.size(store.bins) / 2 - mid_index))
    %{store | min_index: new_min_index, max_index: new_max_index}
  end

  @spec shift_counts(t(), integer()) :: t()
  defp shift_counts(store, shift) do
    new_array = :array.new(:array.size(store.bins), [{:fixed, true}, {:default, 0}])

    new_array =
      Enum.reduce(:array.sparse_to_orddict(store.bins), new_array, fn {k, v}, new_array ->
        :array.set(k + shift, v, new_array)
      end)

    %{store | bins: new_array, offset: store.offset - shift}
  end

  @impl true
  @spec empty?(t()) :: bool()
  def empty?(%{count: 0.0}), do: true
  def empty?(_store), do: false

  @impl true
  @spec total_count(t()) :: float()
  def total_count(%{count: count}), do: count

  @impl true
  @spec min_index(t()) :: integer()
  def min_index(%{count: 0.0}), do: 0
  def min_index(%{min_index: min_index}), do: min_index

  @impl true
  @spec max_index(t()) :: integer()
  def max_index(%{count: 0.0}), do: 0
  def max_index(%{max_index: max_index}), do: max_index

  @impl true
  @spec key_at_rank(t(), float()) :: integer()
  def key_at_rank(store, rank) when rank < 0.0,
    do: key_at_rank(store, 0.0)

  def key_at_rank(store, rank) do
    {step, result} =
      Enum.reduce_while(:array.sparse_to_orddict(store.bins), {:not_end, 0.0}, fn {i, b},
                                                                                  {step, n} ->
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

  @impl true
  @spec to_proto(t()) :: Datadog.Sketch.Protobuf.Store.t()
  def to_proto(%{count: 0.0}), do: %Datadog.Sketch.Protobuf.Store{contiguousBinCounts: nil}

  def to_proto(store) do
    %Datadog.Sketch.Protobuf.Store{
      contiguousBinCounts: :array.to_list(store.bins),
      contiguousBinIndexOffset: store.min_index
    }
  end

  @impl true
  @spec reweight(t(), float()) :: t()
  def reweight(store, weight) do
    new_bins = :array.sparse_map(fn _i, v -> v * weight end, store.bins)
    %{store | bins: new_bins, count: store.count * weight}
  end
end
