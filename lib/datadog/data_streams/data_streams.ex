defmodule Datadog.DataStreams do
  @moduledoc """
  This is a port of the [data-streams-go][dsg] library to Elixir.

  ## Configuration

  Configuration can be done via the `Config` module and your `config/` files.
  We use OpenTelemetry configured values first, so if you are already using
  OpenTelemetry to instrument your application, your service name and
  environment should already be set.

      import Config

      config :opentelemetry, :resource,
        name: "my-elixir-service",
        env: "production"

  If you are not using OpenTelemetry, you can set the service, environment,
  and primary tag via the `:dd_data_streams` application like so:

      import Config

      config :dd_data_streams, :metadata,
        service: "my-elixir-service",
        env: "production",
        primary_tag: "datacenter:d1"

  Once that is configured, you will also want to set the configuration for
  accessing the Datadog agent. This can be done via:

      import Config

      config :dd_data_streams, :agent,
        enabled?: true,
        host: "my-datadog-agent.local",
        port: 8125

  **By default, the agent is disabled and will not send data to Datadog**.
  Without the `host` or `port` configured, we default to "localhost:8125".

  For more information, view the `Datadog.DataStreams.Config` module.

  ## Running

  Once installed, if `:dd_agent_streams` `:agent` is `enabled?`, the
  `Datadog.DataStreams.Aggregator` will start automatically and start sending
  metrics. Just instrument your data pipelines!

  ## Integrations

  - `Datadog.DataStreams.Integrations.Kafka`

  ## Telemetry

  Similar to the golang implementation, we export a couple of `:telemetry`
  metrics that can (and should) be sent to Datadog. These can be done via
  how ever you are sending your application telemetry metrics to Datadog.

  Available metrics include:

  - `datadog.datastreams.aggregator.payloads_in.count` - The number of
    `Datadog.DataStreams.Aggregator.Point`s that were sent to the
    `Datadog.DataStreams.Aggregator`.

  - `datadog.datastreams.aggregator.flushed_payloads.count` - The number of
    successful payloads sent to Datadog.

  - `datadog.datastreams.aggregator.flushed_buckets.count` - The number of
    successful 10 second buckets sent to Datadog.

  - `datadog.datastreams.aggregator.flush_errors.count` - The number of failed
    requests to the Datadog agent (and dropped payloads).

  [dsg]: https://github.com/DataDog/data-streams-go
  """
end
