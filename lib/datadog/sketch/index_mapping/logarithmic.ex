defmodule Datadog.Sketch.IndexMapping.Logarithmic do
  @moduledoc """
  LogarithmicMapping is an IndexMapping that is memory-optimal, that is to say
  that given a targeted relative accuracy, it requires the least number of
  indices to cover a given range of values. This is done by logarithmically
  mapping floating-point values to integers.
  """

  defstruct gamma: 0.0,
            index_offset: 0.0,
            multiplier: 0.0,
            min_indexable_value: 0.0,
            max_indexable_value: 0.0

  @type t :: Datadog.Sketch.IndexMapping.t()

  @behaviour Datadog.Sketch.IndexMapping

  alias Datadog.Sketch.{IndexMapping, Utils}

  @doc """
  Creates a new Logarithmic index mapping with the given accuracy.
  """
  @spec new(float()) :: t() | no_return()
  def new(relative_accuracy) when relative_accuracy < 0 or relative_accuracy > 1,
    do: raise(ArgumentError, message: "The relative accuracy must be between 0 and 1.")

  def new(relative_accuracy) do
    gamma = (1 + relative_accuracy) / (1 - relative_accuracy)
    new(gamma, 0.0)
  end

  @doc """
  Creates a new Logarithmic index mapping with the given gamma
  and index offset.
  """
  @spec new(float(), float()) :: t() | no_return()
  def new(gamma, _index_offset) when gamma <= 1,
    do: raise(ArgumentError, message: "Gamma must be greater than 1.")

  def new(gamma, index_offset) do
    multiplier = 1 / :math.log(gamma)

    %__MODULE__{
      gamma: gamma,
      index_offset: index_offset,
      multiplier: multiplier,
      min_indexable_value:
        max(
          :math.exp((Utils.min_int_32() - index_offset) / multiplier + 1),
          Utils.min_normal_float_64() * gamma
        ),
      max_indexable_value:
        min(
          :math.exp((Utils.max_int_32() - index_offset) / multiplier - 1),
          :math.exp(Utils.exp_overflow()) / (2 * gamma) * (gamma + 1)
        )
    }
  end

  @impl true
  @spec equals(t(), t()) :: boolean()
  def equals(%{gamma: sgamma, index_offset: sindex_offset}, %{
        gamma: ogamma,
        index_offset: oindex_offset
      }) do
    tol = 1.0e-12

    IndexMapping.within_tolerance(sgamma, ogamma, tol) and
      IndexMapping.within_tolerance(sindex_offset, oindex_offset, tol)
  end

  @impl true
  @spec index(t(), float()) :: integer()
  def index(%{index_offset: index_offset, multiplier: multiplier}, value) do
    index = :math.log(value) * multiplier + index_offset

    if index >= 0 do
      trunc(index)
    else
      trunc(index) - 1
    end
  end

  @impl true
  @spec value(t(), integer()) :: float()
  def value(self, index) do
    lower_bound(self, index) * (1 + relative_accuracy(self))
  end

  @impl true
  @spec lower_bound(t(), integer()) :: float()
  def lower_bound(%{index_offset: index_offset, multiplier: multiplier}, index) do
    :math.exp((index - index_offset) / multiplier)
  end

  @impl true
  @spec min_indexable_value(t()) :: float()
  def min_indexable_value(%{min_indexable_value: value}), do: value

  @impl true
  @spec max_indexable_value(t()) :: float()
  def max_indexable_value(%{max_indexable_value: value}), do: value

  @impl true
  @spec relative_accuracy(t()) :: float()
  def relative_accuracy(%{gamma: gamma}) do
    1 - 2 / (1 + gamma)
  end

  @impl true
  @spec to_proto(t()) :: Datadog.Sketch.Protobuf.IndexMapping.t()
  def to_proto(self) do
    %Datadog.Sketch.Protobuf.IndexMapping{
      gamma: self.gamma,
      indexOffset: self.index_offset,
      interpolation: :NONE
    }
  end
end
