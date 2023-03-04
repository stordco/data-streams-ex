defmodule Datadog.Sketch.IndexMapping do
  @moduledoc """
  Basic module for handling various index mapping algorithms.
  """

  @type t :: %{
    __struct__: module(),
    gamma: number(),
    index_offset: number(),
    multiplier: number(),
    min_indexable_value: number(),
    max_indexable_value: number()
  }

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

  @doc "Smallest value of an int32"
  @spec min_int_32() :: integer()
  def min_int_32, do: -2_147_483_648

  @doc "Largest value of an int32"
  @spec max_int_32() :: integer()
  def max_int_32, do: 2_147_483_647

  @doc """
  Checks if an index mapping matches another index mapping.
  """
  @callback equals(t(), t()) :: boolean()

  @callback index(t(), number()) :: integer()

  @callback value(t(), integer()) :: number()

  @callback lower_bound(t(), integer()) :: number()

  @callback relative_accuracy(t()) :: number()

  @doc """
  Returns the minimum positive value that can be mapped to an index.
  """
  @callback min_indexable_value(t()) :: number()

  @doc """
  Returns the maximum positive value that can be mapped to an index.
  """
  @callback max_indexable_value(t()) :: number()

  @doc """
  Returns a `Datadog.Sketch.Protobuf.IndexMapping` Protobuf-able
  struct for the index mapping. Used for sending data to Datadog.
  """
  @callback to_proto(t()) :: Datadog.Sketch.Protobuf.IndexMapping.t()

  @spec to_proto(t()) :: Datadog.Sketch.Protobuf.IndexMapping.t()
  def to_proto(%{__struct__: module} = data) do
    module.to_proto(data)
  end

  @spec within_tolerance(number(), number(), number()) :: bool()
  def within_tolerance(x, y, tolerance) do
    if x == 0 or y == 0 do
      abs(x) <= tolerance and abs(y) <= tolerance
    else
      abs(x - y) <= tolerance * max(abs(x), abs(y))
    end
  end
end
