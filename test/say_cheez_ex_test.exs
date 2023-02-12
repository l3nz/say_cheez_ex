defmodule SayCheezExTest do
  use ExUnit.Case
  doctest SayCheezEx

  @moduledoc """
  Most of these thng are rather hard to test.
  """

  test "Finds first env variable" do
    System.put_env("X1", "10")
    System.put_env("X2", "20")

    assert "10" = SayCheezEx.get_env(["XA", "X1", "X2"])
    assert "20" = SayCheezEx.get_env(["XA", "XB", "X2"])
    assert "?" = SayCheezEx.get_env(["XA", "XB", "XC"])

    assert "10" = SayCheezEx.get_env("X1")
    assert "20" = SayCheezEx.get_env("X2")
    assert "?" = SayCheezEx.get_env("XXX")
  end
end
