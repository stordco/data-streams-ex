defmodule Datadog.DataStreams.Transport do
  @moduledoc """
  An HTTP client for Datadog data streams reporting. It uses the `Finch`
  library for requests.
  """

  alias Datadog.DataStreams.Config

  @headers [
    {"Content-Type", "application/msgpack"},
    {"Content-Encoding", "gzip"},
    {"Datadog-Meta-Lang", "Elixir"}
  ]

  @type response ::
          Finch.Response.t()
          | %{
              body: map(),
              headers: Mint.Types.headers(),
              status: non_neg_integer()
            }

  @doc """
  Sends a MessagePack-ed binary to the Datadog agent. Ensuring it is
  acknowledged by response before returning `:ok`.
  """
  @spec send_pipeline_stats(binary) :: :ok | {:error, any()}
  def send_pipeline_stats(stats) do
    request =
      Finch.build(:post, Config.agent_url("/v0.1/pipeline_stats"), @headers, :zlib.gzip(stats))

    case request |> Finch.request(Datadog.Finch) |> handle_response() do
      {:ok, %Finch.Response{status: 202, body: %{"acknowledged" => true}}} -> :ok
      {:ok, %Finch.Response{body: %{"error" => error}}} -> {:error, error}
      # This is an odd occurrence, but if the status code shows ok, then alright
      {:ok, %Finch.Response{status: status}} when status in 200..399 -> :ok
      {:error, any} -> {:error, any}
    end
  end

  defp handle_response({:error, error}),
    do: {:error, error}

  defp handle_response({:ok, response}) do
    processed_response =
      response
      |> decompress()
      |> json_decode()

    {:ok, processed_response}
  end

  @spec json_decode(Finch.Response.t()) :: response()
  defp json_decode(response) do
    with true <- header?(response.headers, "content-type", "application/json"),
         {:ok, json_body} <- Jason.decode(response.body) do
      %{response | body: json_body}
    else
      _ -> response
    end
  end

  @spec decompress(Finch.Response.t()) :: Finch.Response.t()
  defp decompress(%{body: <<31, 139, 8, _::binary>> = body} = response),
    do: %{response | body: :zlib.gunzip(body)}

  defp decompress(not_compressed_response), do: not_compressed_response

  @spec header?(Mint.Types.headers(), String.t(), String.t()) :: bool()
  defp header?(headers, key, value) do
    Enum.any?(headers, fn {k, v} ->
      String.downcase(k) == key and String.contains?(String.downcase(v), value)
    end)
  end
end
