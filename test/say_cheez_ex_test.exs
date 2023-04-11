defmodule SayCheezExTest do
  # mix test test/say_cheez_ex_test.exs
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
    test "parse dates" do
      dt = "2023-02-15 08:50:19 +0100"

      assert "2023-15" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:ce, :yy, "-", :dd]
               )

      assert "230215.0850" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:yy, :mm, :dd, ".", :h, :m]
               )

      assert "2023-02-15.08:50:19" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:ce, :yy, "-", :mm, "-", :dd, ".", :h, ":", :m, ":", :s]
               )

      assert "2302?.0850" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:yy, :mm, :zebra, ".", :h, :m]
               )
    end

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

  test "first non empty" do
    e = "?"
    assert "x" = SayCheezEx.first_non_empty([e, e, "x", "y", e])

    assert "k" = SayCheezEx.first_non_empty([], "k")
  end

  describe "fn cheez:" do
    test "cheez()" do
      assert :ok =
               SayCheezEx.cheez("x {:build_at}")
               |> date_matches?("x nnnnnn.nnnn")
    end

    test "cheez!()" do
      assert :ok =
               SayCheezEx.cheez!("x {:build_at}")
               |> date_matches?("x nnnnnn.nnnn")
    end
  end

  describe "Tokenizer" do
    test "Plain" do
      assert [
               "v1 ",
               [{:kw, :abc}],
               "-",
               [{:env, "DE"}, {:kw, :fg}],
               "!"
             ] = SayCheezEx.tokenize("v1 {:abc}-{$DE,:fg}!")
    end

    test "No tokens" do
      assert [
               "v1"
             ] = SayCheezEx.tokenize("v1")
    end

    test "Just a token" do
      assert [
               "",
               [{:kw, :abc}]
             ] = SayCheezEx.tokenize("{:abc}")
    end

    test "Expander" do
      System.put_env("EA", "10")

      assert "a: ? - b: 10" =
               SayCheezEx.tokenize("a: {:abc} - b: {$EB,$EA}")
               |> SayCheezEx.expand()
    end

    test "Expander with defaults" do
      assert "a: NONE" =
               SayCheezEx.tokenize("a: {:abc,=NONE}")
               |> SayCheezEx.expand()
    end
  end
end
