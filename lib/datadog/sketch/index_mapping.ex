defmodule Datadog.Sketch.IndexMapping do
  @moduledoc """
  Basic module for handling various index mapping algorithms.
  """

  @type t :: %{
          __struct__: module(),
          gamma: float(),
          index_offset: float(),
          multiplier: float(),
          min_indexable_value: float(),
          max_indexable_value: float()
        }

  @doc """
  Checks if an index mapping matches another index mapping.
  """
  @callback equals(t(), t()) :: boolean()

  @doc """
  Returns an index value after mapping.
  """
  @callback index(t(), float()) :: integer()

  @doc """
  Returns a value after mapping.
  """
  @callback value(t(), integer()) :: float()

  @doc """
  Returns the lower bound the mapping can contain.
  """
  @callback lower_bound(t(), integer()) :: float()

  @doc """
  Returns the relative accuracy of the mapping.
  """
  @callback relative_accuracy(t()) :: float()

  @doc """
  Returns the minimum positive value that can be mapped to an index.
  """
  @callback min_indexable_value(t()) :: float()

  @doc """
  Returns the maximum positive value that can be mapped to an index.
  """
  @callback max_indexable_value(t()) :: float()

  @doc """
  Returns a Protobuf-able struct for the index mapping. Used for
  sending data to Datadog.
  """
  @callback to_proto(t()) :: struct()

  @doc """
  Checks if an index mapping matches another index mapping.
  """
  @spec equals(t(), t()) :: boolean()
  def equals(%{__struct__: module} = self, other), do: module.equals(self, other)

  @doc """
  Returns an index value after mapping.
  """
  @spec index(t(), float()) :: integer()
  def index(%{__struct__: module} = self, value), do: module.index(self, value)

  @doc """
  Returns a value after mapping.
  """
  @spec value(t(), integer()) :: float()
  def value(%{__struct__: module} = self, index), do: module.value(self, index)

  @doc """
  Returns the lower bound the mapping can contain.
  """
  @spec lower_bound(t(), integer()) :: float()
  def lower_bound(%{__struct__: module} = self, index), do: module.lower_bound(self, index)

  @doc """
  Returns the relative accuracy of the mapping.
  """
  @spec relative_accuracy(t()) :: float()
  def relative_accuracy(%{__struct__: module} = self), do: module.relative_accuracy(self)

  @doc """
  Returns the minimum positive value that can be mapped to an index.
  """
  @spec min_indexable_value(t()) :: float()
  def min_indexable_value(%{__struct__: module} = self), do: module.min_indexable_value(self)

  @doc """
  Returns the maximum positive value that can be mapped to an index.
  """
  @spec max_indexable_value(t()) :: float()
  def max_indexable_value(%{__struct__: module} = self), do: module.max_indexable_value(self)

  @doc """
  Returns a Protobuf-able struct for the index mapping. Used for sending
  data to Datadog.
  """
  @spec to_proto(t()) :: struct()
  def to_proto(%{__struct__: module} = self), do: module.to_proto(self)

  @doc """
  Checks if the two values are within the tolerance given.
  """
  @spec within_tolerance(float(), float(), float()) :: bool()
  def within_tolerance(x, y, tolerance) do
    if x == 0 or y == 0 do
      abs(x) <= tolerance and abs(y) <= tolerance
    else
      abs(x - y) <= tolerance * max(abs(x), abs(y))
    end
  end
end
