defmodule Datadog.Sketch.Store do
  @moduledoc """
  Different stores use different data structures and techniques to
  store data. Each with unique trade offs and memory usage.
  """

  @type t :: struct()
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
  """
  @spec add(t(), integer()) :: t()
  def add(%{__struct__: module} = self, index_or_bin), do: module.add(self, index_or_bin)

  @doc """
  Adds a bin type to the store.
  """
  @spec add_bin(t(), bin()) :: t()
  def add_bin(%{__struct__: module} = self, bin), do: module.add_bin(self, bin)

  @doc """
  Adds a number to the store `count` number of times.
  """
  @spec add_with_count(t(), integer(), float()) :: t()
  def add_with_count(%{__struct__: module} = self, index, count),
    do: module.add_with_count(self, index, count)

  @doc """
  Checks if the store has any information in it.
  """
  @spec empty?(t()) :: bool()
  def empty?(%{__struct__: module} = self), do: module.empty?(self)

  @doc """
  Returns the total amount of counts stored.
  """
  @spec total_count(t()) :: float()
  def total_count(%{__struct__: module} = self), do: module.total_count(self)

  @doc """
  Returns the minimum index of the store.
  """
  @spec min_index(t()) :: integer()
  def min_index(%{__struct__: module} = self), do: module.min_index(self)

  @doc """
  Returns the maximum index of the store.
  """
  @spec max_index(t()) :: integer()
  def max_index(%{__struct__: module} = self), do: module.max_index(self)

  @doc """
  Return the key for the value at rank.
  """
  @spec key_at_rank(t(), float()) :: integer()
  def key_at_rank(%{__struct__: module} = self, rank), do: module.key_at_rank(self, rank)

  @doc """
  Returns a struct for Protobuf encoding. Used for sending data to
  Datadog.
  """
  @spec to_proto(t()) :: struct()
  def to_proto(%{__struct__: module} = self), do: module.to_proto(self)

  @doc """
  Maps over all values and multiplies by the given weight.
  """
  @spec reweight(t(), float()) :: t()
  def reweight(%{__struct__: module} = self, weight), do: module.reweight(self, weight)
end
