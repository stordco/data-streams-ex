defmodule Datadog.Readme do
  @moduledoc __DIR__ |> Path.join("../../README.md") |> File.read!()
end
