defmodule SayCheezEx.Graphs.Graphviz do
  alias SayCheezEx.Graphs.Provider
  @behaviour Provider

  @moduledoc """
  Calls a local graphviz command and renders the graph.

  """

  @impl true
  def render!(s),
    do:
      render(s)
      |> Provider.display()

  @impl true
  def render(recipe) do
    Provider.rebuild_if_needed("gv", recipe, &generate_content_graphviz_local/1)
  end

  def generate_content_graphviz_local(recipe) do
    dot_file = Provider.to_temp_file(recipe, "dotfile")
    svg_file = "#{dot_file}.svg"

    case Provider.run_cmd("dot", ["-Tsvg", "-o#{svg_file}", dot_file]) do
      b when is_binary(b) ->
        case File.read(svg_file) do
          {:ok, content} ->
            {:ok,
             content
             |> Provider.clean_up_svg()
             |> Provider.wrap_in_div_for_valid_markdown()}

          {:error, e} ->
            {:error, "Something went wrong: #{inspect(e)}"}
        end

      {:error, e} ->
        {:error, "Something went wrong running dot: #{inspect(e)}"}
    end
  end
end
