defmodule SayCheezEx.Graphs.Graphviz do
  alias SayCheezEx.Graphs.Provider
  @behaviour Provider

  @moduledoc """
  Calls a local graphviz command and renders the graph.

  """

  @impl true
  def render(s) do
    Provider.rebuild_if_needed(s, "gv.dot", &generate_content/1)
  end

  def generate_content(dotFile) do
    svgFile = "#{dotFile}.t.svg"
    _r = Provider.run_cmd("dot", ["-Tsvg", "-o#{svgFile}", dotFile])
    {:ok, c} = File.read(svgFile)
    {:ok, clean_up_svg(c)}
  end

  def demo_render!(s) do
    case render(s) do
      {:ok, v} -> v
      {:error, e} -> inspect(e)
    end
  end

  @doc """
  We want to simplify the SVG that Graphviz generates.
  """

  def clean_up_svg(svg) do
    svg
    # XML header
    |> String.replace(~r/<\?(.|\s)*?\?>/, "")
    # doctype
    |> String.replace(~r/<!DOCTYPE(.|\s)*?>/, "")
    # HTML comments
    |> String.replace(~r/<!--(.|\s)*?-->/, "")
  end
end
