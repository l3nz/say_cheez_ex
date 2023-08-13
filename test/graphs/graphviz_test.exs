defmodule GraphvizTest do
  # mix test  test/graphs/graphviz_test.exs
  use ExUnit.Case, async: true
  use Mimic
  doctest SayCheezEx
  alias SayCheezEx.Graphs.Graphviz

  describe "Graphviz" do
    test "Run simple" do
      assert {:ok, s} = Graphviz.render("digraph { a -> b }")
      assert String.length(s) > 10
    end
  end
end
