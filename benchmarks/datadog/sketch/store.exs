inputs = %{
  "small" => 1..100 |> Enum.to_list() |> Enum.shuffle(),
  "medium" => 1..10_000 |> Enum.to_list() |> Enum.shuffle(),
  "large" => 1..1_000_000 |> Enum.to_list() |> Enum.shuffle()
}

Benchee.run(
  %{
    "dense" => fn list ->
      Enum.reduce(list, Datadog.Sketch.Store.Dense.new(), fn i, store ->
        Datadog.Sketch.Store.Dense.add(store, i)
      end)
    end,
  },
  inputs: inputs
)
