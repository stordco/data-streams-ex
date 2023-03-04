defmodule Datadog.Sketch.Utils do
  @moduledoc """
  Random utility functions to ensure we match the golang
  implementation.
  """

  @doc "Smallest value of an int32"
  @spec min_int_32() :: integer()
  def min_int_32, do: -2_147_483_648

  @doc "Largest value of an int32"
  @spec max_int_32() :: integer()
  def max_int_32, do: 2_147_483_647
end
