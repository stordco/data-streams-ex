defmodule Datadog.DataStreams.MixProject do
  use Mix.Project

  def project do
    [
      app: :dd_data_streams,
      name: "Data Streams Ex",
      description: "DataDog data streams library for Elixir",
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/stordco/data-streams-ex",
      test_coverage: test_coverage()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.19.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: [:dev, :test], runtime: false},
      {:protobuf, "~> 0.10.0"}
    ]
  end

  # Used when packaging for publishing to Hex.pm
  defp package do
    [
      files: ~w(lib mix.exs .formatter.exs README.md CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        Changelog: "https://github.com/stordco/data-streams-ex/releases",
        GitHub: "https://github.com/stordco/data-streams-ex"
      }
    ]
  end

  # Include useful markdown files in built documentation
  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  # Ignore modules that don't require test coverage. Worth noting that
  # we test on Elixir versions < 1.13 which do not include the
  # `ignore_modules` option.
  defp test_coverage do
    [
      ignore_modules: [
        ~r/Enumerable/,
        ~r/Datadog.Sketch.Protobuf/
      ],
      summary: [
        threshold: 0
      ]
    ]
  end
end
