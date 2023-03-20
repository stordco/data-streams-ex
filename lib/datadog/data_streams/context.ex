defmodule Datadog.DataStreams.Context do
  @moduledoc """
  This module deals with storing a `Datadog.DataStreams.Pathway`
  in process, so it can be propagated later on. In Golang, this is handled
  via [`Context`](https://pkg.go.dev/context) which is a grab bag that is
  passed down the whole calling stack. We don't have an equivalent in Elixir,
  so we instead piggy back off of [`OpenTelemetry.Baggage`][OTB]. This
  essentially lets us do the same thing without needing to manually pass
  data down the calling stack.

  **This is optional**. If you do not have Open Telemetry installed or
  setup, functions here will not propagate the Pathway. You will need
  to manually propagate it in your application.

  [OTB]: https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/src/otel_baggage.erl
  """

  @context_key "dd-datastreams"
  @hash "pathway.hash"

  alias Datadog.DataStreams.{Pathway, Tags}

  @doc """
  Returns the current existing Pathway from OpenTelemetry. If
  there is no Pathway in the current context, `nil` will be
  returned
  """
  @spec get() :: Pathway.t() | nil
  def get() do
    OpenTelemetry.Ctx.get_value(@context_key, nil)
  end

  @doc """
  Sets the given Pathway to the current Pathway in OpenTelemetry.
  """
  @spec set(Pathway.t()) :: Pathway.t()
  def set(%Pathway{} = pathway) do
    OpenTelemetry.Ctx.set_value(@context_key, pathway)
    OpenTelemetry.Ctx.set_value(@hash, pathway.hash)
    pathway
  end

  @doc """
  Removes the current existing Pathway from OpenTelemetry. Returns
  the value that existing in OpenTelemetry.
  """
  @spec clear() :: Pathway.t() | nil
  def clear() do
    case get() do
      nil ->
        nil

      pathway ->
        OpenTelemetry.Ctx.remove(@context_key)
        pathway
    end
  end

  @doc """
  Sets a checkpoint on the current existing Pathway. If one does
  not exist, a new Pathway is created from the edge tags and
  returned.
  """
  @spec set(Tags.input()) :: Pathway.t()
  def set_checkpoint(tags) do
    case get() do
      nil ->
        tags
        |> Pathway.new_pathway()
        |> set()

      pathway ->
        pathway
        |> Pathway.set_checkpoint(tags)
        |> set()
    end
  end
end
