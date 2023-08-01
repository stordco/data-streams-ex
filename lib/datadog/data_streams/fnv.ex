defmodule Datadog.DataStreams.FNV do
  @moduledoc """
  Fowler-Noll-Vo variant 1 64-bit hash implementation. Use for
  `Datadog.DataStreams.Pathway` hashing.

  Based off the excellent asaaki work in the [`fnv` library][fnv].

  [fnv]: https://github.com/asaaki/fnv.ex
  """

  import Bitwise

  @bit 64
  @prime (2 <<< 39) + (2 <<< 7) + 0xB3
  @offset_basis 14_695_981_039_346_656_037

  @doc """
  Fowler-Noll-Vo variant 1 64-bit hash implementation.
  """
  @spec hash64(binary) :: integer
  def hash64(data) when is_binary(data) do
    calculate_hash(@bit, @prime, @offset_basis, data)
  end

  defp calculate_hash(_, _, current_hash, <<>>),
    do: current_hash

  defp calculate_hash(bits, prime, current_hash, <<octet::8, rest::binary>>) do
    new_hash = current_hash |> :erlang.*(prime) |> bxor(octet) |> rem(2 <<< (bits - 1))
    calculate_hash(bits, prime, new_hash, rest)
  end
end
