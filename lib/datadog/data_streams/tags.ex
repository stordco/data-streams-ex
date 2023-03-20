defmodule Datadog.DataStreams.Tags do
  @moduledoc """
  A helper module to enumerate and filter over data stream tags.
  """

  # Taken from the datadog java library:
  # https://github.com/DataDog/dd-trace-java/blob/d9c3727d0b04c95d07b3d07f5c81b152f87bc479/dd-trace-core/src/main/java/datadog/trace/core/datastreams/TagsProcessor.java#L9
  # These are all of the tags that can be used for backlogs and edge tags
  @edge_tags ~w(type direction topic partition group exchange)

  # Taken from the datadog java library:
  # https://cs.github.com/DataDog/dd-trace-java/blob/eb58b4066946a415c506d03319bf728968dc3aad/dd-trace-core/src/main/java/datadog/trace/core/datastreams/DefaultPathwayContext.java#L53
  # These are the allowed tags to be hashed for pathways
  @hashable_tags ~w(group type direction topic exchange)

  @typedoc """
  The type all tags are internally mapped to.
  """
  @type t :: [{binary(), binary()}]

  @typedoc """
  An encoded list of tags. This is the format that Datadog expects when we send
  data. It's a list of key value binary joined via `:`. For example:
  "partition:1", "group:some-consumer-group", "topic:a-topic".
  """
  @type encoded :: [binary()]

  @typedoc """
  All allowed tag input types. This could be any one of the following examples:

      [{:key, "value"}, {:key_two, "value_two"}]
      [{"key", "value"}, {"key_two", "value_two"}]
      %{key: "value", key_two: "value_two"}
      %{"key" => "value", "key_two" => "value_two"}
      ["key:value", "key_two:value_two"]

  """
  @type input :: [{binary | atom(), binary()}] | %{(binary() | atom()) => binary()} | [binary()]

  @doc """
  Parses any type of tag input and normalizes it to our internal `t:t` type.
  Note this will also filter out invalid data like nil values.

  ## Examples

      iex> [{:key, "value"}, {:key_two, "value_two"}]
      ...> |> Tags.parse()
      [{"key", "value"}, {"key_two", "value_two"}]

      iex> [{"key", "value"}, {"key_two", "value_two"}]
      ...> |> Tags.parse()
      [{"key", "value"}, {"key_two", "value_two"}]

      iex> %{key: "value", key_two: "value_two"}
      ...> |> Tags.parse()
      [{"key", "value"}, {"key_two", "value_two"}]

      iex> %{"key" => "value", "key_two" => "value_two"}
      ...> |> Tags.parse()
      [{"key", "value"}, {"key_two", "value_two"}]

      iex> ["key:value", "key_two:value_two"]
      ...> |> Tags.parse()
      [{"key", "value"}, {"key_two", "value_two"}]

      iex> [{"key", nil}, {"key_two", "value_two"}]
      ...> |> Tags.parse()
      [{"key_two", "value_two"}]

  """
  @spec parse(input) :: t
  def parse(input) when is_map(input),
    do: input |> Enum.to_list() |> parse()

  def parse(input) when is_list(input),
    do: input |> Enum.map(&parse_list_item/1) |> Enum.reject(&is_nil/1)

  defp parse_list_item({key, value}) when is_nil(key) or is_nil(value),
    do: nil

  defp parse_list_item({key, value}),
    do: {to_string(key), to_string(value)}

  defp parse_list_item(input) when is_binary(input) do
    case String.split(input, ":", parts: 2) do
      [key, value] -> {key, value}
      _ -> nil
    end
  end

  @doc """
  Filters a list of tags to a known list of allowed tags. This varies based on
  the context of where it is used.

  ## Examples

      iex> [{"key", "value"}, {"topic", "one"}, {"key_two", "value_two"}]
      ...> |> Tags.filter(:hash)
      [{"topic", "one"}]

  """
  @spec filter(t, atom()) :: t
  def filter(tags, :edge),
    do: Enum.filter(tags, fn {k, _v} -> k in @edge_tags end)

  def filter(tags, :hash),
    do: Enum.filter(tags, fn {k, _v} -> k in @hashable_tags end)

  def filter(tags, _where), do: tags

  @doc """
  Tags a list of tags and converts them to a list of binary tags. This is the
  format that Datadog expects. This also orders the tags to ensure it matches
  other languages when hashing.

  ## Examples

      iex> Tags.encode([{"tag_two", "value_two"}, {"tag", "value"}])
      ["tag:value", "tag_two:value_two"]

  """
  @spec encode(t) :: [binary()]
  def encode(tags) do
    tags
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
  end
end
