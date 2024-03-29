defmodule Datadog.DataStreams.AggregatorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  alias Datadog.DataStreams.Aggregator

  setup do
    Application.delete_env(:data_streams, :agent)
    {:ok, state: %{send_timer: nil, ts_type_current_buckets: %{}, ts_type_origin_buckets: %{}}}
  end

  describe "add/1" do
    test "sends Aggregator.Point to module when not started" do
      refute Process.whereis(Aggregator)
      assert :ok = Aggregator.add(%Aggregator.Point{})
    end

    @tag :capture_log
    test "sends Aggregator.Point to module when registered" do
      Application.put_env(:data_streams, :agent, enabled?: true)
      start_supervised!(Aggregator)
      assert :ok = Aggregator.add(%Aggregator.Point{})
    end

    test "sends Aggregator.Offset to module when not started" do
      refute Process.whereis(Aggregator)
      assert :ok = Aggregator.add(%Aggregator.Offset{})
    end

    @tag :capture_log
    test "sends Aggregator.Offset to module when registered" do
      Application.put_env(:data_streams, :agent, enabled?: true)
      start_supervised!(Aggregator)
      assert :ok = Aggregator.add(%Aggregator.Offset{})
    end
  end

  describe "init/1" do
    test "ignores if enabled? is set to false" do
      assert :ignore = Aggregator.init(enabled?: false)
      refute :ignore == Aggregator.init(enabled?: true)
    end

    test "sets a send timer" do
      {:ok, state} = Aggregator.init(enabled?: true)
      assert is_reference(state.send_timer)
    end
  end

  describe "handle_cast/2 {:add, point}" do
    test "adds aggregator point to buckets", %{state: state} do
      assert {:noreply, new_state} =
               Aggregator.handle_cast(
                 {:add,
                  %Aggregator.Point{
                    edge_tags: ["type:test"],
                    hash: 9_808_874_869_469_701_221,
                    parent_hash: 17_210_443_572_488_294_574,
                    pathway_latency: 10_000_000_000,
                    edge_latency: 5_000_000_000,
                    timestamp: 1_678_471_420_000_000_000
                  }},
                 state
               )

      assert %{
               1_678_471_420_000_000_000 => %Aggregator.Bucket{
                 groups: %{
                   9_808_874_869_469_701_221 => %Aggregator.Group{
                     edge_tags: ["type:test"],
                     hash: 9_808_874_869_469_701_221,
                     parent_hash: 17_210_443_572_488_294_574,
                     pathway_latency: _,
                     edge_latency: _
                   }
                 },
                 latest_commit_offsets: [],
                 latest_produce_offsets: [],
                 start: 1_678_471_420_000_000_000,
                 duration: 10_000_000_000
               }
             } = new_state.ts_type_current_buckets

      assert %{
               1_678_471_410_000_000_000 => %Aggregator.Bucket{
                 groups: %{
                   9_808_874_869_469_701_221 => %Aggregator.Group{
                     edge_tags: ["type:test"],
                     hash: 9_808_874_869_469_701_221,
                     parent_hash: 17_210_443_572_488_294_574,
                     pathway_latency: _,
                     edge_latency: _
                   }
                 },
                 latest_commit_offsets: [],
                 latest_produce_offsets: [],
                 start: 1_678_471_410_000_000_000,
                 duration: 10_000_000_000
               }
             } = new_state.ts_type_origin_buckets
    end

    test "adds aggregator offset to bucket", %{state: state} do
      offset = %Aggregator.Offset{
        offset: 13,
        timestamp: 1_687_986_447_538_450_340,
        type: :commit,
        tags: %{
          "consumer_group" => "test-group",
          "partition" => 0,
          "topic" => "test-topic",
          "type" => "kafka_commit"
        }
      }

      assert {:noreply, new_state} = Aggregator.handle_cast({:add, offset}, state)

      assert %{
               1_687_986_440_000_000_000 => %Aggregator.Bucket{
                 groups: %{},
                 latest_commit_offsets: [^offset],
                 latest_produce_offsets: [],
                 start: 1_687_986_440_000_000_000,
                 duration: 10_000_000_000
               }
             } = new_state.ts_type_current_buckets

      # It should find and update the existing data, not add to the bucket.
      assert {:noreply, ^new_state} = Aggregator.handle_cast({:add, offset}, new_state)
    end
  end

  describe "handle_info/2 {task_ref, {:ok, count}}" do
    test "logs and doesn't modify state on success", %{state: state} do
      logs =
        capture_log(fn ->
          assert {:noreply, ^state} = Aggregator.handle_info({make_ref(), {:ok, 10}}, state)
        end)

      assert logs =~ "sent metrics to Datadog"
    end
  end

  describe "handle_info/2 {task_ref, {:error, error}}" do
    test "logs and doesn't modify state on failure", %{state: state} do
      logs =
        capture_log(fn ->
          assert {:noreply, ^state} = Aggregator.handle_info({make_ref(), {:error, :test}}, state)
        end)

      assert logs =~ "Error sending metrics to Datadog"
    end
  end
end
