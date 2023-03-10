defmodule Datadog.DataStreams.ConfigTest do
  use ExUnit.Case, async: true

  alias Datadog.DataStreams.Config

  doctest Datadog.DataStreams.Config

  setup do
    Application.delete_env(:opentelemetry, :resource)
    Application.delete_env(:dd_data_streams, :agent)
    Application.delete_env(:dd_data_streams, :metadata)
    :ok
  end
end
