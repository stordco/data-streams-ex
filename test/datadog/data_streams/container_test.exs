defmodule Datadog.DataStreams.ContainerTest do
  # Test samples were taken from the original data-streams-go PR
  # https://github.com/DataDog/data-streams-go/pull/29/files#diff-024e3d4ff20badf054922b05099e1f8c8bfb9b562ce2ccf9bfdb5c5378432b19

  use ExUnit.Case, async: true

  alias Datadog.DataStreams.Container

  test "parse_container_id/1 can parse a stream (example 1)" do
    file = ~s"""
    other_line
    10:hugetlb:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    9:cpuset:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    8:pids:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    7:freezer:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    6:cpu,cpuacct:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    5:perf_event:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    4:blkio:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    3:devices:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    2:net_cls,net_prio:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa"
  end

  test "parse_container_id/1 can parse a stream (example 2)" do
    file = ~s"""
    10:hugetlb:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa"
  end

  test "parse_container_id/1 can parse a stream (example 3)" do
    file = ~s"""
    10:hugetlb:/kubepods
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) === nil
  end

  test "parse_container_id/1 can parse a stream (example 4)" do
    file = ~s"""
    11:hugetlb:/ecs/55091c13-b8cf-4801-b527-f4601742204d/432624d2150b349fe35ba397284dea788c2bf66b885d14dfc1569b01890ca7da
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "432624d2150b349fe35ba397284dea788c2bf66b885d14dfc1569b01890ca7da"
  end

  test "parse_container_id/1 can parse a stream (example 5)" do
    file = ~s"""
    1:name=systemd:/docker/34dc0b5e626f2c5c4c5170e34b10e7654ce36f0fcd532739f4445baabea03376
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "34dc0b5e626f2c5c4c5170e34b10e7654ce36f0fcd532739f4445baabea03376"
  end

  test "parse_container_id/1 can parse a stream (example 6)" do
    file = ~s"""
    1:name=systemd:/uuid/34dc0b5e-626f-2c5c-4c51-70e34b10e765
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "34dc0b5e-626f-2c5c-4c51-70e34b10e765"
  end

  test "parse_container_id/1 can parse a stream (example 7)" do
    file = ~s"""
    1:name=systemd:/ecs/34dc0b5e626f2c5c4c5170e34b10e765-1234567890
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "34dc0b5e626f2c5c4c5170e34b10e765-1234567890"
  end

  test "parse_container_id/1 can parse a stream (example 8)" do
    file = ~s"""
    1:name=systemd:/docker/34dc0b5e626f2c5c4c5170e34b10e7654ce36f0fcd532739f4445baabea03376.scope
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "34dc0b5e626f2c5c4c5170e34b10e7654ce36f0fcd532739f4445baabea03376"
  end

  test "parse_container_id/1 can parse a stream (example 9)" do
    file = ~s"""
    1:name=systemd:/nope
    2:pids:/docker/34dc0b5e626f2c5c4c5170e34b10e7654ce36f0fcd532739f4445baabea03376
    3:cpu:/invalid
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "34dc0b5e626f2c5c4c5170e34b10e7654ce36f0fcd532739f4445baabea03376"
  end

  test "parse_container_id/1 can parse a stream (example 10)" do
    file = ~s"""
    other_line
    12:memory:/system.slice/garden.service/garden/6f265890-5165-7fab-6b52-18d1
    11:rdma:/
    10:freezer:/garden/6f265890-5165-7fab-6b52-18d1
    9:hugetlb:/garden/6f265890-5165-7fab-6b52-18d1
    8:pids:/system.slice/garden.service/garden/6f265890-5165-7fab-6b52-18d1
    7:perf_event:/garden/6f265890-5165-7fab-6b52-18d1
    6:cpu,cpuacct:/system.slice/garden.service/garden/6f265890-5165-7fab-6b52-18d1
    5:net_cls,net_prio:/garden/6f265890-5165-7fab-6b52-18d1
    4:cpuset:/garden/6f265890-5165-7fab-6b52-18d1
    3:blkio:/system.slice/garden.service/garden/6f265890-5165-7fab-6b52-18d1
    2:devices:/system.slice/garden.service/garden/6f265890-5165-7fab-6b52-18d1
    1:name=systemd:/system.slice/garden.service/garden/6f265890-5165-7fab-6b52-18d1
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "6f265890-5165-7fab-6b52-18d1"
  end

  test "parse_container_id/1 can parse a stream (example 11)" do
    file = ~s"""
    1:name=systemd:/system.slice/garden.service/garden/6f265890-5165-7fab-6b52-18d1
    """

    {:ok, stream} = StringIO.open(file)

    assert Container.parse_container_id(IO.binstream(stream, :line)) ===
             "6f265890-5165-7fab-6b52-18d1"
  end

  @tag :tmp_dir
  test "read_container_id/1 can parse a file", %{tmp_dir: tmp_dir} do
    cid = "8c046cb0b72cd4c99f51b5591cd5b095967f58ee003710a45280c28ee1a9c7fa"

    cgroup_contents =
      "10:hugetlb:/kubepods/burstable/podfd52ef25-a87d-11e9-9423-0800271a638e/" <> cid

    file_path = Path.join(tmp_dir, "fake-cgroup")

    File.write!(file_path, cgroup_contents)

    assert ^cid = Container.read_container_id(file_path)
  end
end
