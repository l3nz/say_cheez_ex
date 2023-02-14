defmodule SayCheezExTest do
  use ExUnit.Case
  doctest SayCheezEx

  @moduledoc """
  Most of these things are rather hard to test.
  """

  def date_matches?(date, regex_templ) do
    {:ok, rx} =
      "^#{regex_templ}$"
      |> String.replace("n", "\\d")
      |> String.replace(".", "\\.")
      |> Regex.compile()

    case String.match?(date, rx) do
      true -> :ok
      _ -> {:nomatch, date, regex_templ, rx}
    end
  end

  describe "git integration:" do
    test "dates" do
      assert :ok =
               SayCheezEx.info(:git_date)
               |> date_matches?("nnnn-nn-nn.nn:nn:nn")

      assert :ok =
               SayCheezEx.info(:git_date_compact)
               |> date_matches?("nnnnnn.nnnn")
    end
  end

  describe "build info:" do
    test "dates" do
      assert :ok =
               SayCheezEx.info(:build_at)
               |> date_matches?("nnnnnn.nnnn")

      assert :ok =
               SayCheezEx.info(:build_at_full)
               |> date_matches?("nnnn-nn-nn.nn:nn:nn")

      assert :ok =
               SayCheezEx.info(:build_at_day)
               |> date_matches?("nnnn-nn-nn")
    end
  end

  describe "Other variables:" do
    test "camelized project name" do
      # in mix.exs, it is :say_cheez_ex
      assert "SayCheezEx" = SayCheezEx.info(:project_name)
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
