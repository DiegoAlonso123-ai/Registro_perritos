defmodule PerritosTest do
  use ExUnit.Case
  doctest Perritos

  test "greets the world" do
    assert Perritos.hello() == :world
  end
end
