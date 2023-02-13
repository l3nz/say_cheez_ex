defmodule SayCheezExTest do
  use ExUnit.Case
  doctest SayCheezEx

  @moduledoc """
  Most of these things are rather hard to test.
  """

  def dateMatches?(sDate, sRegexTempl) do
    {:ok, rx} =
      "^#{sRegexTempl}$"
      |> String.replace("n", "\\d")
      |> String.replace(".", "\\.")
      |> Regex.compile()

    case String.match?(sDate, rx) do
      true -> :ok
      _ -> {:nomatch, sDate, sRegexTempl, rx}
    end
  end

  describe "git integration:" do
    test "dates" do
      assert :ok =
               SayCheezEx.info(:git_date)
               |> dateMatches?("nnnn-nn-nn.nn:nn:nn")

      assert :ok =
               SayCheezEx.info(:git_date_compact)
               |> dateMatches?("nnnnnn.nnnn")
    end
  end

  describe "build info:" do
    test "dates" do
      assert :ok =
               SayCheezEx.info(:build_at)
               |> dateMatches?("nnnnnn.nnnn")

      assert :ok =
               SayCheezEx.info(:build_at_full)
               |> dateMatches?("nnnn-nn-nn.nn:nn:nn")

      assert :ok =
               SayCheezEx.info(:build_at_day)
               |> dateMatches?("nnnn-nn-nn")
    end
  end

  describe "Environment variables:" do
    test "finds first env variable" do
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
end
