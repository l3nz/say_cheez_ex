defmodule SayCheezEx.Graphs.Plantuml do
  alias SayCheezEx.Graphs.Provider
  @behaviour Provider

  @doc """
  PlantUML has an online server, e.g. this:

      @startuml
      Bob -> Alice : hello
      @enduml

  Will be translated into this:

      https://www.plantuml.com/plantuml/svg/SoWkIImgAStDuNBAJrBGjLDmpCbCJbMmKiX8pSd9vt98pKi1IW80

  So you don't need to have PlantUML installed.

  Still we use the `curl` command to actually request the file.

  """

  @impl true
  def render(s) do
    Provider.rebuild_if_needed(s, "pu.uml", &generate_content/1)
  end

  def demo_render!(s) do
    {:ok, md} = render(s)
    md
  end

  @doc """


      curl -oxxx.svg http://www.plantuml.com/plantuml/svg/\~h407374617274756d6c0a416c6963652d3e426f62203a204920616d207573696e67206865780a40656e64756d6c


  """

  def generate_content(umlFile) do
    svgFile = "#{umlFile}.t.svg"
    {:ok, uml_source} = File.read(umlFile)
    url = make_plantuml_url_simple(uml_source)
    # IO.puts(url)
    _r = Provider.run_cmd("curl", ["-o#{svgFile}", url])
    {:ok, c} = File.read(svgFile)
    {:ok, c}
  end

  @doc """
  PlantUML allows simple encoding - makes URLs very long,
  but it's trivial to implement as described in https://plantuml.com/text-encoding

  One can play along with different test cases with the online editor
  at https://www.plantuml.com/plantuml/uml/~h407374617274756d6c0a416c6963652d3e426f62203a204920616d207573696e67206865780a40656e64756d6c


  E.g.

    https://www.plantuml.com/plantuml/svg/~h407374617274756d6c0a416c6963652d3e426f62203a204920616d207573696e67206865780a40656e64756d6c

  The text does not require the startuml / enduml tags.

  Examples:

      iex> Plantuml.make_plantuml_url_simple("SayCheezEx -> You : Elixir rocks")
      "https://www.plantuml.com/plantuml/svg/~h536179436865657A4578202D3E20596F75203A20456C6978697220726F636B73"

  """

  def make_plantuml_url_simple(s) do
    :erlang.binary_to_list(s)
    |> Enum.map(&encodeByte/1)
    |> Enum.join()
    |> as_plantuml_simple_url(:svg)
  end

  def as_plantuml_simple_url(payload, mode), do: as_plantuml_url("~h#{payload}", mode)
  def as_plantuml_url(payload, :svg), do: "https://www.plantuml.com/plantuml/svg/#{payload}"
  def as_plantuml_url(payload, :editor), do: "https://www.plantuml.com/plantuml/uml/#{payload}"

  def encodeByte(b) do
    case b do
      bb when bb < 16 -> "0#{Integer.to_string(bb, 16)}"
      bo when bo > 255 -> "XX"
      _ -> Integer.to_string(b, 16)
    end
  end

  @doc """
  Should be possible without external dependencies

  https://stackoverflow.com/questions/8742169/how-can-i-compress-a-list-with-zlib-in-erlang-and-decompress-it-back

  """
  def make_plantuml_url_deflated(s) do
    :tdb
  end
end
