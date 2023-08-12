defmodule PlantumlTest do
  # mix test  test/graphs/graphviz_test.exs
  use ExUnit.Case, async: true
  use Mimic

  alias SayCheezEx.Graphs.Plantuml
  doctest Plantuml

  describe "URL Encoding" do
    test "Simple" do
      assert "https://www.plantuml.com/plantuml/svg/~h426F62202D3E20416C696365203A2068656C6C6F" =
               Plantuml.make_plantuml_url_simple("Bob -> Alice : hello")
    end

    test "With \n" do
      assert "https://www.plantuml.com/plantuml/svg/~h0A42202D3E20413A2068656C6C6F0A0A" =
               Plantuml.make_plantuml_url_simple("\nB -> A: hello\n\n")
    end
  end
end
