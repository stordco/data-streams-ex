# Data Streams Ex

This is a port of the [data-streams-go](https://github.com/DataDog/data-streams-go) library to Elixir.

## Introduction

This product is meant to measure end to end latency in async pipelines. It's in an Alpha phase. We currently support instrumentations of async pipelines using Kafka. Integrations with other systems will follow soon.

## Glossary

- Data stream: A set of services connected together via *queues*
- Pathway: A single branch of connected services
- Queue: A connection between two services
- Edge latency: Latency of a queue between two services
- Latency from origin: Latency from the first tracked service, down to the current service
- Checkpoint: records at what time a specific operation on a payload occurred (eg: The payload was sent to Kafka). The product can then measure latency between checkpoints.

The product can measure edge latency, and latency from origin, for a set of checkpoints connected together via queues.
To do so, we propagate timestamps, and a hash of the path that messages took with the payload.

## Installation

Just add [`data_streams`](https://hexdocs.pm/data_streams) to your `mix.exs` file like so:

<!-- {x-release-please-start-version} -->
```elixir
def deps do
  [
    {:data_streams, "~> 1.2.0"}
  ]
end
```
<!-- {x-release-please-end} -->

Documentation is automatically generated and published to [HexDocs](https://hexdocs.pm/data_streams).

## Elixir instrumentation

**Prerequisites**
- Datadog Agent 7.34.0+
- latest version of [the data streams library](https://github.com/stordco/data-streams-ex)

You will need to configure the pipeline with the trace agent URL and enable it to start on application start. This can be done via your `config/` files:

```elixir
config :data_streams, :pipeline,
  enabled?: true,
  host: "localhost",
  port: 8126
```

The host and port should point to your Datadog agent.

The instrumentation relies on creating checkpoints at various points in your data stream services with specific tags, recording the pathway that messages take along the way. For a complete picture of your services, you will also need to configure some metadata about the current service running. You can do this in your `config/` files as well:

```elixir
config :data_streams, :metadata,
  service: "my-service",
  env: "production",
  primary_tag: "datacenter:d1" # You can leave this blank if you don't have a primary tag.
```

We recommend you keep these tags matching all your other instrumentation, like Open Telemetry and `:telemetry`, to ensure Datadog can aggregate data accurately.

### Integrations

This library contains integration modules to help integrate with various async data pipelines. See one of these modules for usage details.

- `Datadog.DataStreams.Integrations.Kafka`
