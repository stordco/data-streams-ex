defmodule Datadog.Sketch.Store.DenseTest do
  use ExUnit.Case, async: true

  alias Datadog.Sketch.Store.Dense

  doctest Datadog.Sketch.Store.Dense

  @doc """
  This is a super verbose test to ensure we adjust the internal erlang
  `:array` the same way the golang implementation works. This is usually the
  first step to debugging why it's not working as intended. You can run this
  test in the sketches-go code base with this:

  ```golang
  store := NewDenseStore()
  store.AddWithCount(97, 751.18)
  store.AddWithCount(57, 7648)
  store.AddWithCount(274, 975.18)
  store.AddWithCount(27, 48.37)
  store.AddWithCount(167, 37.48)
  store.AddWithCount(65, 12.48)
  store.AddWithCount(37, 847.4)
  t.Logf("test value: %v", store)
  ```

  It should output something similar to this string:

  ```text
  &{[0 48.37 0 0 0 0 0 0 0 0 0 847.4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7648 0 0 0 0 0 0 0 12.48 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 751.18 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 37.48 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 975.18 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0] 10320.09 26 27 274}
  ```

  The large string is the slice of numbers, with 10320.09 as the count, 26
  as the offset, 27 as the min index, and 274 as the max index.

  """
  test "adjusts erlang array to match golang implementation" do
    store =
      Dense.new()
      |> Dense.add_with_count(97, 751.18)
      |> Dense.add_with_count(57, 7648)
      |> Dense.add_with_count(274, 975.18)
      |> Dense.add_with_count(27, 48.37)
      |> Dense.add_with_count(167, 37.48)
      |> Dense.add_with_count(65, 12.48)
      |> Dense.add_with_count(37, 847.4)

    assert 10_320.09 = store.count
    assert 26 = store.offset
    assert 27 = store.min_index
    assert 274 = store.max_index

    assert [
             0,
             48.37,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             847.4,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             7648,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             12.48,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             751.18,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             37.48,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             975.18,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0
           ] = :array.to_list(store.bins)
  end

  describe "Enumerable" do
    test "count/1" do
      store =
        Dense.new()
        |> Dense.add(1)
        |> Dense.add(2)
        |> Dense.add(3)

      assert 3 = Enum.count(store)
    end

    test "member?/2" do
      store =
        Dense.new()
        |> Dense.add(1)
        |> Dense.add(2)
        |> Dense.add(1)
        |> Dense.add(1)

      assert Enum.member?(store, {1, 3.0})
      assert Enum.member?(store, {2, 1.0})
      refute Enum.member?(store, {3, 1.0})
    end

    test "reduce/3" do
      store =
        Dense.new()
        |> Dense.add(1)
        |> Dense.add(2)
        |> Dense.add(1)
        |> Dense.add(1)

      assert [{1, 3.0}, {2, 1.0}] = Enum.to_list(store)
    end
  end
end
