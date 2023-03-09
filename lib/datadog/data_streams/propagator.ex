defmodule Datadog.DataStreams.Propagator do
  @moduledoc """
  Handles propagating `Datadog.DataStreams.Pathway` via encoding and adding
  to message headers.
  """

  import Protobuf.Wire.Varint, only: [defdecoderp: 2]

  alias Datadog.DataStreams.Pathway

  @propagation_key "dd-pathway-ctx"
  @propagation_key_base64 "dd-pathway-ctx-base64"

  @doc """
  Returns the well known header key for propagating encoded pathway data.

  ## Examples

      iex> Propagator.propagation_key()
      "#{@propagation_key}"

  """
  @spec propagation_key() :: String.t()
  def propagation_key, do: @propagation_key

  @doc """
  Returns the well known base64 encoded header key for propagating encoded
  pathway data.

  ## Examples

      iex> Propagator.propagation_key_base64()
      "#{@propagation_key_base64}"

  """
  @spec propagation_key_base64() :: String.t()
  def propagation_key_base64, do: @propagation_key_base64

  @doc """
  Encodes a pathway into a list or map of headers.

  ## Examples

      iex> Propagator.encode_header([], %Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000})
      [{"#{@propagation_key}", <<174, 208, 17, 141, 62, 199, 215, 238, 224, 159, 240, 170, 211, 97, 224, 159, 240, 170, 211, 97>>}]

      iex> Propagator.encode_header(%{}, %Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000})
      %{"#{@propagation_key}" => <<174, 208, 17, 141, 62, 199, 215, 238, 224, 159, 240, 170, 211, 97, 224, 159, 240, 170, 211, 97>>}

  """
  @spec encode_header(list({binary(), binary()}), Pathway.t()) :: list({binary(), binary()})
  @spec encode_header(%{required(binary()) => binary()}, Pathway.t()) :: %{
          required(binary()) => binary()
        }
  @spec encode_header(any(), Pathway.t()) :: any()
  def encode_header(headers, pathway) when is_map(headers),
    do: headers |> Enum.to_list() |> encode_header(pathway) |> Map.new()

  def encode_header(headers, pathway) when is_list(headers) do
    removed_headers =
      headers
      |> Enum.map(fn {key, value} -> {String.downcase(key), value} end)
      |> Enum.reject(fn {key, _value} ->
        key in [@propagation_key_base64, @propagation_key]
      end)

    removed_headers ++ [{@propagation_key, encode(pathway)}]
  end

  def encode_header(value), do: value

  @doc """
  Encodes a pathway to a string able to be placed in a header.

  ## Examples

      # Verified from golang implementation
      iex> Propagator.encode(%Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000})
      <<174, 208, 17, 141, 62, 199, 215, 238, 224, 159, 240, 170, 211, 97, 224, 159, 240, 170, 211, 97>>

      # Verified from golang implementation
      iex> Propagator.encode(%Pathway{hash: 2003974475228685984, pathway_start: 1677628446000000000, edge_start: 1677628446000000000})
      <<160, 166, 244, 238, 42, 140, 207, 27, 224, 212, 148, 167, 211, 97, 224, 212, 148, 167, 211, 97>>

  """
  @spec encode(Pathway.t()) :: binary()
  def encode(pathway) do
    :binary.encode_unsigned(pathway.hash, :little) <>
      encode_time(pathway.pathway_start) <> encode_time(pathway.edge_start)
  end

  @doc """
  Encodes a pathway to a string able to be placed in a header.

  ## Examples

      # Verified from golang implementation
      iex> Propagator.encode_str(%Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000})
      "rtARjT7H1+7gn/Cq02Hgn/Cq02E="

      # Verified from golang implementation
      iex> Propagator.encode_str(%Pathway{hash: 2003974475228685984, pathway_start: 1677628446000000000, edge_start: 1677628446000000000})
      "oKb07iqMzxvg1JSn02Hg1JSn02E="

  """
  @spec encode_str(Pathway.t()) :: String.t()
  def encode_str(pathway) do
    pathway
    |> encode()
    |> Base.encode64()
  end

  # Close
  @doc """
  Encodes a pathway time using zigzag encoding.

  ## Examples

      # Verified from golang implementation
      iex> Propagator.encode_time(1677632342000000000)
      <<224, 159, 240, 170, 211, 97>>

  """
  @spec encode_time(non_neg_integer()) :: binary()
  def encode_time(time) do
    (time / 1_000_000)
    |> floor()
    |> Protobuf.Wire.Zigzag.encode()
    |> Protobuf.Wire.Varint.encode()
    |> IO.iodata_to_binary()
  end

  @doc """
  Decodes a pathway from a list or map of headers. If no matching header, or
  if the header is invalid, `nil` is returned.

  ## Examples

      iex> Propagator.decode_header([{"#{@propagation_key_base64}", "rtARjT7H1+7gn/Cq02Hgn/Cq02E="}])
      %Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000}

      iex> Propagator.decode_header(%{"#{@propagation_key}" => <<174, 208, 17, 141, 62, 199, 215, 238, 224, 159, 240, 170, 211, 97, 224, 159, 240, 170, 211, 97>>})
      %Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000}

      iex> Propagator.decode_header(%{"content-type" => "application-json"})
      nil

  """
  @spec decode_header(list({binary(), binary()})) :: Pathway.t() | nil
  @spec decode_header(%{required(binary()) => binary()}) :: Pathway.t() | nil
  @spec decode_header(any()) :: nil
  def decode_header(headers) when is_map(headers),
    do: headers |> Enum.to_list() |> decode_header()

  def decode_header(headers) when is_list(headers) do
    found_header =
      headers
      |> Enum.map(fn {key, value} -> {String.downcase(key), value} end)
      |> Enum.find(fn {key, _value} ->
        key in [@propagation_key_base64, @propagation_key]
      end)

    case found_header do
      {@propagation_key_base64, value} -> decode_str(value)
      {@propagation_key, value} -> decode(value)
      _ -> nil
    end
  end

  def decode_header(_), do: nil

  @doc """
  Tries to decode a value into a pathway.

  ## Examples

      # Verified from golang implementation
      iex> Propagator.decode(<<174, 208, 17, 141, 62, 199, 215, 238, 224, 159, 240, 170, 211, 97, 224, 159, 240, 170, 211, 97>>)
      %Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000}

      iex> Propagator.decode("invalid")
      nil

  """
  @spec decode(binary()) :: Pathway.t() | nil
  def decode(<<hash::binary-size(8), pathway::binary-size(6), edge::binary-size(6)>>) do
    with pathway_start when not is_nil(pathway_start) <- decode_time(pathway),
         edge_start when not is_nil(edge_start) <- decode_time(edge) do
      %Pathway{
        hash: :binary.decode_unsigned(hash, :little),
        pathway_start: pathway_start,
        edge_start: edge_start
      }
    else
      _ -> nil
    end
  end

  def decode(_value), do: nil

  @doc """
  Tries to decode a Base64 encoded value into a pathway.

  ## Examples

      # Verified from golang implementation
      iex> Propagator.decode_str("rtARjT7H1+7gn/Cq02Hgn/Cq02E=")
      %Pathway{hash: 17210443572488294574, pathway_start: 1677632342000000000, edge_start: 1677632342000000000}

      iex> Propagator.decode_str("invalid")
      nil

  """
  @spec decode_str(String.t()) :: Pathway.t() | nil
  def decode_str(str) do
    case Base.decode64(str) do
      {:ok, str} -> decode(str)
      :error -> nil
    end
  end

  @doc """
  Decodes a pathway binary time from zigzag encoding.

  ## Examples

      # Verified from golang implementation
      iex> Propagator.decode_time(<<224, 159, 240, 170, 211, 97>>)
      1677632342000000000

      iex> Propagator.decode_time(<<1, 2, 3, 4>>)
      nil

  """
  @spec decode_time(binary()) :: non_neg_integer() | nil
  def decode_time(binary) do
    case decode_time_binary(binary) do
      [time] -> Protobuf.Wire.Zigzag.decode(time) * 1_000_000
      _ -> nil
    end
  end

  defp decode_time_binary(<<bin::bits>>), do: decode_time_binary(bin, [])

  defp decode_time_binary(<<>>, acc), do: acc

  defdecoderp decode_time_binary(acc) do
    decode_time_binary(rest, [value | acc])
  end
end
