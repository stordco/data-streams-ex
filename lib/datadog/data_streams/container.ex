defmodule Datadog.DataStreams.Container do
  @moduledoc """
  Logic for linking current running container id to data stream traces.
  """

  use Agent

  # the path to the cgroup file where we can find the container id if one exists.
  @cgroup_path "/proc/self/cgroup"

  @uuid_source Regex.source(
                 ~r/[0-9a-f]{8}[-_][0-9a-f]{4}[-_][0-9a-f]{4}[-_][0-9a-f]{4}[-_][0-9a-f]{12}|[0-9a-f]{8}(?:-[0-9a-f]{4}){4}$/
               )
  @container_source Regex.source(~r/[0-9a-f]{64}/)
  @task_source Regex.source(~r/[0-9a-f]{32}-\d+/)

  @exp_line ~r/^\d+:[^:]*:(.+)$/
  @exp_container_id Regex.compile!("(#{@uuid_source}|#{@container_source}|#{@task_source})(?:.scope)?$")

  @doc """
  Starts the agent and stores the current container id in memory.
  """
  def start_link(_opts) do
    Agent.start_link(&read_container_id/0, name: __MODULE__)
  end

  @doc """
  Returns the current container id.
  """
  @spec get :: String.t() | nil
  def get do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  Attempts to return the container id from the cgroup path (`#{@cgroup_path}`). Empty on failure.
  """
  @spec read_container_id :: String.t() | nil
  def read_container_id,
    do: read_container_id(@cgroup_path)

  @doc """
  Attempts to return the container id from the provided file path. Empty on failure.
  """
  @spec read_container_id(String.t()) :: String.t() | nil
  def read_container_id(file) do
    file
    |> File.stream!()
    |> parse_container_id()
  rescue
    _ -> nil
  end

  @doc """
  Attempts to return the container id from the provided file stream. Empty on failure.
  """
  def parse_container_id(stream) do
    stream
    |> Stream.map(&parse_line/1)
    |> Stream.filter(fn value -> not is_nil(value) end)
    |> Enum.at(0)
  rescue
    _ -> nil
  end

  defp parse_line(line) do
    with [_part_one, part_two] <- Regex.run(@exp_line, line),
         [_part_one, container_id] <- Regex.run(@exp_container_id, part_two) do
      container_id
    else
      _ -> nil
    end
  end
end
