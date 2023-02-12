defmodule SayCheezExTest do
  use ExUnit.Case
  doctest SayCheezEx

  test "greets the world" do
    assert SayCheezEx.hello() == :world
  end
end
