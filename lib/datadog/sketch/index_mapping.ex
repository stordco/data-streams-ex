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

  @callback index(t(), float()) :: integer()

  @callback value(t(), integer()) :: float()

  @callback lower_bound(t(), integer()) :: float()

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
  Returns a `Datadog.Sketch.Protobuf.IndexMapping` Protobuf-able
  struct for the index mapping. Used for sending data to Datadog.
  """
  @callback to_proto(t()) :: Datadog.Sketch.Protobuf.IndexMapping.t()

  @doc """
  The value at which golang math.Exp overflows. This is golang
  specific, but we want to match implementation details.
  """
  @spec exp_overflow() :: number()
  def exp_overflow, do: 7.094361393031e+02

  @doc """
  The minimum value of golang float64. 2^(-1022)
  """
  @spec min_normal_float_64() :: number()
  def min_normal_float_64, do: 2.2250738585072014e-308

  @doc """
  Checks if an index mapping matches another index mapping.
  """
  @spec equals(t(), t()) :: boolean()
  def equals(%{__struct__: module} = self, other), do: module.equals(self, other)

  @doc """
  Checks if an index mapping matches another index mapping.
  """
  @spec index(t(), float()) :: integer()
  def index(%{__struct__: module} = self, value), do: module.index(self, value)

  @spec value(t(), integer()) :: float()
  def value(%{__struct__: module} = self, index), do: module.value(self, index)

  @spec lower_bound(t(), integer()) :: float()
  def lower_bound(%{__struct__: module} = self, index), do: module.lower_bound(self, index)

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
  Returns a `Datadog.Sketch.Protobuf.IndexMapping` Protobuf-able
  struct for the index mapping. Used for sending data to Datadog.
  """
  @spec to_proto(t()) :: Datadog.Sketch.Protobuf.IndexMapping.t()
  def to_proto(%{__struct__: module} = self), do: module.to_proto(self)

  @spec within_tolerance(float(), float(), float()) :: bool()
  def within_tolerance(x, y, tolerance) do
    if x == 0 or y == 0 do
      abs(x) <= tolerance and abs(y) <= tolerance
    else
      abs(x - y) <= tolerance * max(abs(x), abs(y))
    end
  end
end
