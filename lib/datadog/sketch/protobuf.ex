# File generated from the `sketches-go` library.
# https://github.com/DataDog/sketches-go/blob/master/ddsketch/pb/ddsketch.proto

defmodule Datadog.Sketch.Protobuf.IndexMapping.Interpolation do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :NONE, 0
  field :LINEAR, 1
  field :QUADRATIC, 2
  field :CUBIC, 3
end

defmodule Datadog.Sketch.Protobuf.DDSketch do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :mapping, 1, type: Datadog.Sketch.Protobuf.IndexMapping
  field :positiveValues, 2, type: Datadog.Sketch.Protobuf.Store
  field :negativeValues, 3, type: Datadog.Sketch.Protobuf.Store
  field :zeroCount, 4, type: :double
end

defmodule Datadog.Sketch.Protobuf.IndexMapping do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :gamma, 1, type: :double
  field :indexOffset, 2, type: :double
  field :interpolation, 3, type: Datadog.Sketch.Protobuf.IndexMapping.Interpolation, enum: true
end

defmodule Datadog.Sketch.Protobuf.Store.BinCountsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :key, 1, type: :sint32
  field :value, 2, type: :double
end

defmodule Datadog.Sketch.Protobuf.Store do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field :binCounts, 1, repeated: true, type: Datadog.Sketch.Protobuf.Store.BinCountsEntry, map: true
  field :contiguousBinCounts, 2, repeated: true, type: :double, packed: true, deprecated: false
  field :contiguousBinIndexOffset, 3, type: :sint32
end
