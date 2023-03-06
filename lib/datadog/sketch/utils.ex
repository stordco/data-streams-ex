defmodule Datadog.Sketch.Utils do
  @moduledoc """
  Random utility functions to ensure we match the golang
  implementation.
  """

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
end
