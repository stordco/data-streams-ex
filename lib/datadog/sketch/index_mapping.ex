defmodule Datadog.Sketch.IndexMapping do
  @moduledoc """
  Basic module for handling various index mapping algorithms. All functions in
  this module proxy to the respective index mapping implementation module.
  """

  @typedoc """
  A general struct that has index mapping data. Every index mapping
  implementation _must_ contain this data.
  """
  @type t :: %{
          __struct__: module(),
          gamma: float(),
          index_offset: float(),
          multiplier: float()
        }

  @doc """
  Checks if an index mapping matches another index mapping.
  """
  @callback equals(t(), t()) :: boolean()

  @doc """
  Returns value after mapping.
  """
  @callback index(t(), float()) :: integer()

  @doc """
  Takes a mapped value and returns the original value within the set accuracy.
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
  Returns a Protobuf-able struct for the index mapping. Used for
  sending data to Datadog.
  """
  @callback to_proto(t()) :: struct()

  @doc """
  Checks if an index mapping matches another index mapping.

      iex> implementation_one = IndexMapping.Logarithmic.new(0.0000000000001)
      ...> implementation_two = IndexMapping.Logarithmic.new(0.0000000000002)
      ...> IndexMapping.equals(implementation_one, implementation_two)
      true

      iex> implementation_one = IndexMapping.Logarithmic.new(0.01)
      ...> implementation_two = IndexMapping.Logarithmic.new(0.00001)
      ...> IndexMapping.equals(implementation_one, implementation_two)
      false

  """
  @spec equals(t(), t()) :: boolean()
  def equals(%{__struct__: module} = self, other), do: module.equals(self, other)

  @doc """
  Returns value after mapping.

      iex> index_mapping = IndexMapping.Logarithmic.new(0.01)
      ...> IndexMapping.index(index_mapping, 115)
      237

      iex> index_mapping = IndexMapping.Logarithmic.new(0.001)
      ...> IndexMapping.index(index_mapping, 12345678901234567890)
      21979

  """
  @spec index(t(), float()) :: integer()
  def index(%{__struct__: module} = self, value), do: module.index(self, value)

  @doc """
  Takes a mapped value and returns the original value within the set accuracy.

      iex> index_mapping = IndexMapping.Logarithmic.new(0.01)
      ...> IndexMapping.value(index_mapping, 237)
      115.59680764552533

      iex> index_mapping = IndexMapping.Logarithmic.new(0.001)
      ...> IndexMapping.value(index_mapping, 21979)
      1.23355147396003e19

  """
  @spec value(t(), integer()) :: float()
  def value(%{__struct__: module} = self, index), do: module.value(self, index)

  @doc """
  Returns the lower bound the mapping can contain.

      iex> index_mapping = IndexMapping.Logarithmic.new(0.01)
      ...> IndexMapping.lower_bound(index_mapping, 0)
      1.0

      iex> index_mapping = IndexMapping.Logarithmic.new(0.01)
      ...> IndexMapping.lower_bound(index_mapping, 10)
      1.2214109013609646

  """
  @spec lower_bound(t(), integer()) :: float()
  def lower_bound(%{__struct__: module} = self, index), do: module.lower_bound(self, index)

  @doc """
  Returns the lower bound the mapping can contain.

      iex> index_mapping = IndexMapping.Logarithmic.new(0.01)
      ...> IndexMapping.relative_accuracy(index_mapping)
      0.009999999999999898

  """
  @spec relative_accuracy(t()) :: float()
  def relative_accuracy(%{__struct__: module} = self), do: module.relative_accuracy(self)

  @doc """
  Returns a Protobuf-able struct for the index mapping. Used for
  sending data to Datadog.

      iex> index_mapping = IndexMapping.Logarithmic.new(0.01)
      ...> IndexMapping.to_proto(index_mapping)
      %Datadog.Sketch.Protobuf.IndexMapping{gamma: 1.02020202020202, interpolation: :NONE}

  """
  @spec to_proto(t()) :: struct()
  def to_proto(%{__struct__: module} = self), do: module.to_proto(self)

  @doc """
  Checks if the two values are within the tolerance given.

  ## Examples

      iex> IndexMapping.within_tolerance(90, 134, 50)
      true

      iex> IndexMapping.within_tolerance(0.00128, 0.00864, 0.01)
      false

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
