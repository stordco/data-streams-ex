defmodule Datadog.Sketch.Store do
  @moduledoc """
  Different stores use different data structures and techniques to store data.
  Each with unique trade offs and memory usage. All functions in this module
  proxy to the respective index mapping implementation module.

  All stores implement the `Enumerable` protocol to iterate over all stored
  data easily.
  """

  @typedoc """
  A basic struct. This is used to keep tight type definitions.
  Each store implements this struct differently.
  """
  @type t :: struct()

  @typedoc """
  A concise way to specify an index and count in one arg.
  """
  @type bin :: %{index: integer(), count: float()}

  @doc """
  Adds a number to the store.
  """
  @callback add(t(), integer()) :: t()

  @doc """
  Adds a bin type to the store.
  """
  @callback add_bin(t(), bin()) :: t()

  @doc """
  Adds multiple bin types to the store.
  """
  @callback add_bins(t(), [bin()]) :: t()

  @doc """
  Adds a number to the store `count` number of times.
  """
  @callback add_with_count(t(), integer(), float()) :: t()

  @doc """
  Checks if the store has any information in it.
  """
  @callback empty?(t()) :: bool()

  @doc """
  Returns the total amount of counts stored.
  """
  @callback total_count(t()) :: float()

  @doc """
  Returns the minimum index of the store.
  """
  @callback min_index(t()) :: integer()

  @doc """
  Returns the maximum index of the store.
  """
  @callback max_index(t()) :: integer()

  @doc """
  Return the key for the value at rank.
  """
  @callback key_at_rank(t(), float()) :: integer()

  @doc """
  Returns a struct for Protobuf encoding. Used for sending data to
  Datadog.
  """
  @callback to_proto(t()) :: struct()

  @doc """
  Maps over all values and multiplies by the given weight.
  """
  @callback reweight(t(), float()) :: t()

  @doc """
  Adds a number to the store.

  ## Examples

      iex> %Store.Dense{} = Store.add(Store.Dense.new(), 100)

  """
  @spec add(t(), integer()) :: t()
  def add(%{__struct__: module} = self, index_or_bin), do: module.add(self, index_or_bin)

  @doc """
  Adds a bin type to the store.

  ## Examples

      iex> %Store.Dense{} = Store.add_bin(Store.Dense.new(), %{index: 100, count: 13.13})

  """
  @spec add_bin(t(), bin()) :: t()
  def add_bin(%{__struct__: module} = self, bin), do: module.add_bin(self, bin)

  @doc """
  Adds multiple bin types to the store.

  ## Examples

        iex> %Store.Dense{} = Store.add_bins(Store.Dense.new(), [
        ...>   %{index: 100, count: 13.13},
        ...>   %{index: 20, count: 2342.4}
        ...> ])

  """
  @spec add_bins(t(), [bin()]) :: t()
  def add_bins(%{__struct__: module} = self, bins), do: module.add_bins(self, bins)

  @doc """
  Adds a number to the store `count` number of times.

  ## Examples

      iex> %Store.Dense{} = Store.add_with_count(Store.Dense.new(), 100, 13.13)

      iex> %Store.Dense{} = Store.add_with_count(Store.Dense.new(), 987, 8.3e12)

  """
  @spec add_with_count(t(), integer(), float()) :: t()
  def add_with_count(%{__struct__: module} = self, index, count),
    do: module.add_with_count(self, index, count)

  @doc """
  Checks if the store has any information in it.

  ## Examples

      iex> store = Store.Dense.new()
      ...> Store.empty?(store)
      true

      iex> store = Store.add(Store.Dense.new(), 754)
      ...> Store.empty?(store)
      false

  """
  @spec empty?(t()) :: bool()
  def empty?(%{__struct__: module} = self), do: module.empty?(self)

  @doc """
  Returns the total amount of counts stored.

  ## Examples

      iex> store = Store.Dense.new()
      ...> Store.total_count(store)
      0.0

      iex> store = Store.add_with_count(Store.Dense.new(), 754, 42.42)
      ...> Store.total_count(store)
      42.42

  """
  @spec total_count(t()) :: float()
  def total_count(%{__struct__: module} = self), do: module.total_count(self)

  @doc """
  Returns the minimum index of the store.

  ## Examples

      iex> store = Store.Dense.new()
      ...> Store.min_index(store)
      0

  """
  @spec min_index(t()) :: integer()
  def min_index(%{__struct__: module} = self), do: module.min_index(self)

  @doc """
  Returns the maximum index of the store.

  ## Examples

        iex> store = Store.Dense.new()
        ...> Store.max_index(store)
        0

  """
  @spec max_index(t()) :: integer()
  def max_index(%{__struct__: module} = self), do: module.max_index(self)

  @doc """
  Return the key for the value at rank.

  ## Examples

        iex> store = Store.add(Store.Dense.new(), 128)
        ...> Store.key_at_rank(store, 0.0)
        128

  """
  @spec key_at_rank(t(), float()) :: integer()
  def key_at_rank(%{__struct__: module} = self, rank), do: module.key_at_rank(self, rank)

  @doc """
  Returns a struct for Protobuf encoding. Used for sending data to
  Datadog.


  ## Examples

        iex> %Datadog.Sketch.Protobuf.Store{} = Store.to_proto(Store.Dense.new())

  """
  @spec to_proto(t()) :: struct()
  def to_proto(%{__struct__: module} = self), do: module.to_proto(self)

  @doc """
  Maps over all values and multiplies by the given weight.

  ## Examples

        iex> store = Store.add_bins(Store.Dense.new(), [
        ...>   %{index: 4, count: 10.0},
        ...>   %{index: 2, count: 20.0},
        ...>   %{index: 6, count: 30.0}
        ...> ])
        ...> store = Store.reweight(store, 2)
        ...> Store.total_count(store)
        120.0

  """
  @spec reweight(t(), float()) :: t()
  def reweight(%{__struct__: module} = self, weight), do: module.reweight(self, weight)
end
