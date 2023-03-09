defmodule Datadog.ReadmeTest do
  @moduledoc """
  This is the most cheesy thing I've ever written in Elixir. But it works.
  """

  use ExUnit.Case, async: true

  # Elixir 1.15 is going to be absolute FIRE :fire:
  # doctest_file Path.join(__DIR__, "../README.md")

  # Until then, we do it the less awesome, but still
  # possible manual way.
  doctest Datadog.Readme
end
