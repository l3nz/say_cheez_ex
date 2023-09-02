defmodule ProviderTest do
  # mix test  test/graphs/provider_test.exs
  use ExUnit.Case, async: true
  use Mimic

  alias SayCheezEx.Graphs.Provider
  doctest Provider

  describe "Shellout" do
    test "Run non-existing command" do
      assert {:error, :cmd_not_found} = Provider.run_cmd("zebra", [])
    end

    test "Run existing command" do
      result = Provider.run_cmd("dot", ["-V"])

      assert String.contains?(result, "graphviz"), "Out: #{result}"
    end

    test "String hash" do
      assert "D012F68144ED0F121D3CC330A17EEC528C2E7D59" = Provider.string_hash("pippo")
    end
  end

  describe "HTTP Client" do
    test "Simple" do
      # tries multiple requests
      assert {:ok, body1} = Provider.trivial_http_get_client("https://www.elixir.com")
      assert {:ok, body2} = Provider.trivial_http_get_client("https://www.elixir.com/?1234")

      assert String.length(body1) == String.length(body2)
    end
  end

  describe "Caching" do
    @unique_recipe "ze<b>ra #{Enum.random(1..1_000_000_000_000)}"

    test "Simple" do
      # I'm not finding this recipe
      assert {:miss} = Provider.cached?("test", @unique_recipe)

      Provider.write_to_cache("test", @unique_recipe, "Io sono MD")

      # Now I find it
      assert {:hit, "Io sono MD"} = Provider.cached?("test", @unique_recipe)
    end
  end

  describe "Clean up SVG" do
    test "clean SVG comments" do
      assert "<a>cc" = Provider.clean_up_svg("<a><!-- aa\n bbb -->cc")
      assert "<a>cc<b>dd" = Provider.clean_up_svg("<a><!-- aa\n bbb -->cc<b><!-- aa\n bbb -->dd")
    end

    test "clean XML header" do
      assert "<a>xy" =
               Provider.clean_up_svg(
                 "<a>x<?xml version='1.0' encoding='UTF-8' standalone='no'?>y"
               )
    end

    test "clean doctype header" do
      assert "<a>xy" =
               Provider.clean_up_svg(
                 "<a>x<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\"\n \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">y"
               )
    end
  end
end
