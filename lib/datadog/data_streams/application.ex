defmodule Datadog.DataStreams.Application do
  @moduledoc false

  use Application

  @doc false
  @spec start(Application.start_type(), term()) :: {:ok, pid} | {:error, term()}
  def start(_type, _args) do
    children = [
      {Finch, name: Datadog.Finch},
      Datadog.DataStreams.Aggregator
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
