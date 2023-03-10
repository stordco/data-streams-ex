defmodule Datadog.DataStreams.Config do
  @moduledoc """
  Responsible for parsing application configuration to usable chunks
  in the application.
  """

  @doc """
  Returns the configured service for this application.

  First, it will try accessing the configured service for `:open_telemetry`.
  If that is not set, it tries to use the service configured for
  `:dd_data_streams`. If that is not set, it falls back to
  "unnamed-elixir-service".

  Note, this will not pull open telemetry attributes set via environment
  variables.

  ## Examples

      iex> Application.put_env(:opentelemetry, :resource, service: %{name: "my-elixir-service"})
      ...> Config.service()
      "my-elixir-service"

      iex> Application.put_env(:dd_data_streams, :metadata, service: "my-data-streams-service")
      ...> Config.service()
      "my-data-streams-service"

      iex> Config.service()
      "unnamed-elixir-service"

  """
  @spec service() :: String.t()
  def service() do
    otel_service_name =
      :opentelemetry
      |> Application.get_env(:resource, [])
      |> Keyword.get(:service, %{})
      |> Map.get(:name)

    if is_nil(otel_service_name) do
      :dd_data_streams
      |> Application.get_env(:metadata, [])
      |> Keyword.get(:service, "unnamed-elixir-service")
    else
      otel_service_name
    end
  end

  @doc """
  Returns the configured environment tag for this application.

  First, it will try accessing the configured service for `:open_telemetry`.
  If that is not set, it tries to use the service configured for
  `:dd_data_streams`. If that is not set, it falls back to an empty string.

  Note, this will not pull open telemetry attributes set via environment
  variables.

  ## Examples

      iex> Application.put_env(:opentelemetry, :resource, service: %{env: "production"})
      ...> Config.env()
      "production"

      iex> Application.put_env(:dd_data_streams, :metadata, env: "staging")
      ...> Config.env()
      "staging"

      iex> Config.env()
      ""

  """
  @spec env() :: String.t()
  def env() do
    otel_service_env =
      :opentelemetry
      |> Application.get_env(:resource, [])
      |> Keyword.get(:service, %{})
      |> Map.get(:env)

    if is_nil(otel_service_env) do
      :dd_data_streams
      |> Application.get_env(:metadata, [])
      |> Keyword.get(:env, "")
    else
      otel_service_env
    end
  end

  @doc """
  Returns the configured primary tag for all `Datadog.DataStreams.Pathway`s.

  Usually this reflects a data center or some other top level partition for
  metrics.

  If this is not set, it will fall back to an empty string.

  ## Examples

      iex> Application.put_env(:dd_data_streams, :metadata, primary_tag: "datacenter:d1")
      ...> Config.primary_tag()
      "datacenter:d1"

      iex> Config.primary_tag()
      ""

  """
  @spec primary_tag() :: String.t()
  def primary_tag() do
    :dd_data_streams
    |> Application.get_env(:metadata, [])
    |> Keyword.get(:primary_tag, "")
  end

  @doc """
  Checks if the Datadog agent is enabled. By default it is disabled. Disabling
  will cause the `Datadog.DataStreams.Aggregator` process to not start or send
  data to the agent.

  ## Examples

      iex> Config.agent_enabled?
      false

      iex> Application.put_env(:dd_data_streams, :agent, enabled?: true)
      ...> Config.agent_enabled?
      true

  """
  @spec agent_enabled? :: bool()
  def agent_enabled? do
    :dd_data_streams
    |> Application.get_env(:agent, [])
    |> Keyword.get(:enabled?, false)
  end

  @doc """
  Returns a full path to the Datadog agent, joining the given path string.
  If this configuration is not set, we default to "localhost:8126".

  ## Examples

      iex> Config.agent_url("/info")
      "http://localhost:8126/info"

      iex> Application.put_env(:dd_data_streams, :agent, [host: "my-agent.local", port: 1234])
      ...> Config.agent_url("/info")
      "http://my-agent.local:1234/info"

  """
  @spec agent_url(String.t()) :: String.t()
  def agent_url(path) do
    config = Application.get_env(:dd_data_streams, :agent, [])
    host = Keyword.get(config, :host, "localhost")
    port = Keyword.get(config, :port, 8126)

    URI.to_string(%URI{
      host: host,
      port: port,
      path: path,
      scheme: "http"
    })
  end
end
