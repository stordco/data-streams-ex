defmodule Datadog.Sketch.IndexMapping.Logarithmic do
  @moduledoc """
  LogarithmicMapping is an IndexMapping that is memory-optimal, that is to say
  that given a targeted relative accuracy, it requires the least number of
  indices to cover a given range of values. This is done by logarithmically
  mapping floating-point values to integers.

  Note, since Erlang (and therefor Elixir) do math pretty differently than
  golang, this module does not contain a min or max indexable value., This
  follows in line with the Erlang philosophy of "let it crash" and simplifies
  our logic handling.
  """

  defstruct gamma: 0.0,
            index_offset: 0.0,
            multiplier: 0.0

  @type t :: Datadog.Sketch.IndexMapping.t()

  @behaviour Datadog.Sketch.IndexMapping

  alias Datadog.Sketch.IndexMapping

  @doc """
  Creates a new Logarithmic index mapping with the given accuracy.

  ## Examples

      iex> Logarithmic.new(-1)
      ** (ArgumentError) The relative accuracy must be between 0, and 1.

      iex> Logarithmic.new(0.01)
      %Logarithmic{gamma: 1.02020202020202, multiplier: 49.99833328888678}

      iex> Logarithmic.new(0.0001)
      %Logarithmic{gamma: 1.0002000200020003, multiplier: 4999.999983331928}

  """
  @spec new(float()) :: t() | no_return()
  def new(relative_accuracy) when relative_accuracy < 0 or relative_accuracy > 1,
    do: raise(ArgumentError, message: "The relative accuracy must be between 0, and 1.")

  def new(relative_accuracy) do
    gamma = (1 + relative_accuracy) / (1 - relative_accuracy)
    new(gamma, 0.0)
  end

  @doc """
  Creates a new Logarithmic index mapping with the given gamma
  and index offset.

      iex> Logarithmic.new(0.5, 0.0)
      ** (ArgumentError) Gamma must be greater than 1.

      iex> Logarithmic.new(1.0002000200020003, 0.0)
      %Logarithmic{gamma: 1.0002000200020003, multiplier: 4999.999983331928}

      iex> Logarithmic.new(1.0002000200020003, 1.5)
      %Logarithmic{gamma: 1.0002000200020003, index_offset: 1.5, multiplier: 4999.999983331928}

  """
  @spec new(float(), float()) :: t() | no_return()
  def new(gamma, _index_offset) when gamma <= 1,
    do: raise(ArgumentError, message: "Gamma must be greater than 1.")

  def new(gamma, index_offset) do
    multiplier = 1 / :math.log(gamma)

    %__MODULE__{
      gamma: gamma,
      index_offset: index_offset,
      multiplier: multiplier
    }
  end

  @doc """
  Checks if an index mapping matches another index mapping.

      iex> implementation_one = Logarithmic.new(0.0000000000001)
      ...> implementation_two = Logarithmic.new(0.0000000000002)
      ...> Logarithmic.equals(implementation_one, implementation_two)
      true

      iex> implementation_one = Logarithmic.new(0.01)
      ...> implementation_two = Logarithmic.new(0.00001)
      ...> Logarithmic.equals(implementation_one, implementation_two)
      false

  """
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

  @doc """
  Returns value after mapping via logarithmic equation.

      iex> index_mapping = Logarithmic.new(0.01)
      ...> Logarithmic.index(index_mapping, 115)
      237

      iex> index_mapping = Logarithmic.new(0.001)
      ...> Logarithmic.index(index_mapping, 12345678901234567890)
      21979

  """
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

  @doc """
  Takes a mapped value and returns the original value within the set accuracy.

      iex> index_mapping = Logarithmic.new(0.01)
      ...> Logarithmic.value(index_mapping, 237)
      115.59680764552533

      iex> index_mapping = Logarithmic.new(0.001)
      ...> Logarithmic.value(index_mapping, 21979)
      1.23355147396003e19

  """
  @impl true
  @spec value(t(), integer()) :: float()
  def value(self, index) do
    lower_bound(self, index) * (1 + relative_accuracy(self))
  end

  @doc """
  Returns the lower bound the mapping can contain.

      iex> index_mapping = Logarithmic.new(0.01)
      ...> Logarithmic.lower_bound(index_mapping, 0)
      1.0

      iex> index_mapping = Logarithmic.new(0.01)
      ...> Logarithmic.lower_bound(index_mapping, 10)
      1.2214109013609646

  """
  @impl true
  @spec lower_bound(t(), integer()) :: float()
  def lower_bound(%{index_offset: index_offset, multiplier: multiplier}, index) do
    :math.exp((index - index_offset) / multiplier)
  end

  @doc """
  Returns the lower bound the mapping can contain.

      iex> index_mapping = Logarithmic.new(0.01)
      ...> Logarithmic.relative_accuracy(index_mapping)
      0.009999999999999898

  """
  @impl true
  @spec relative_accuracy(t()) :: float()
  def relative_accuracy(%{gamma: gamma}) do
    1 - 2 / (1 + gamma)
  end

  @doc """
  Returns a Protobuf-able struct for the index mapping., Used for
  sending data to Datadog.

      iex> index_mapping = Logarithmic.new(0.01)
      ...> Logarithmic.to_proto(index_mapping)
      %Datadog.Sketch.Protobuf.IndexMapping{gamma: 1.02020202020202, interpolation: :NONE}

  """
  @impl true
  @spec to_proto(t()) :: struct()
  def to_proto(self) do
    %Datadog.Sketch.Protobuf.IndexMapping{
      gamma: self.gamma,
      indexOffset: self.index_offset,
      interpolation: :NONE
    }
  end
end
