defmodule GraphvizTest do
  # mix test  test/graphs/graphviz_test.exs
  use ExUnit.Case, async: true
  use Mimic
  doctest SayCheezEx
  alias SayCheezEx.Graphs.Provider
  alias SayCheezEx.Graphs.Graphviz

  describe "Shellout" do
    test "Run non-existing command" do
      assert {:error, :cmd_not_found} = Provider.run_cmd("zebra", [])
    end

    test "Run existing command" do
      assert "" = Provider.run_cmd("dot", ["-V"])
    end

    test "String hash" do
      assert "D012F68144ED0F121D3CC330A17EEC528C2E7D59" = Provider.string_hash("pippo")
    end
  end

  describe "Graphviz" do
    test "Run simple" do
      assert {:ok, s} = Graphviz.render("digraph { a -> b }")
      IO.puts(s)
    end

    test "clean SVG comments" do
      assert "<a>cc" = Graphviz.clean_up_svg("<a><!-- aa\n bbb -->cc")
      assert "<a>cc<b>dd" = Graphviz.clean_up_svg("<a><!-- aa\n bbb -->cc<b><!-- aa\n bbb -->dd")
    end

    test "clean XML header" do
      assert "<a>xy" =
               Graphviz.clean_up_svg(
                 "<a>x<?xml version='1.0' encoding='UTF-8' standalone='no'?>y"
               )
    end

    test "clean doctype header" do
      assert "<a>xy" =
               Graphviz.clean_up_svg(
                 "<a>x<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\"\n \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">y"
               )
    end
  end
end
