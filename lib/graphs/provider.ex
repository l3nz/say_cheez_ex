defmodule SayCheezEx.Graphs.Provider do
  @moduledoc """
  The interface for a graph provider.

  - checks if a such a provider is available, given the
    providers' own configuration
  - renders a graph to some HTML that can be embedded

  """

  @doc """
  ..
  """
  @callback render(String.t()) :: {:ok, String.t()} | {:ko, any()}

  @doc """
  Runs an external command.

  It returns a binary that captures STDOUT if all went well,
  or a tuple `{:error, e}` if something went bonkers.

  If it's trying to call a command that does not exist on your
  local environment, returns `{:error, :cmd_not_found}`.

  """

  def run_cmd(cmd, parameters) do
    try do
      case System.cmd(cmd, parameters) do
        {result, 0} ->
          String.trim(result)

        e ->
          {:error, e}
      end
    rescue
      e ->
        case e do
          %ErlangError{original: :enoent} -> {:error, :cmd_not_found}
          _ -> {:error, e}
        end
    end
  end

  @doc """
  Given a recipe *s* for a graph, first tries a cache and
  then call a "builder" function to create it.

  So if the SVG was already generated, we load it from
  disk - if not, we build it again.


  ## Builder

  The builder expects a file on disk where the source recipe
  is. This is useful because local commands read from a
  file and write to a file.

  It returns {:ok, svg_text} or {:error, reason}
  that will be used to display a result.

  """

  def rebuild_if_needed(s, extension, fnBuilder) do
    dir = System.tmp_dir!()
    filename = "SayCheezEx_#{string_hash(s)}_#{extension}"
    tmp_file_dot = Path.join(dir, filename)
    tmp_file_svg = "#{tmp_file_dot}.svg"

    File.write!(tmp_file_dot, s)

    # calling dot - reading from file, writing to file
    {:ok, body} = fnBuilder.(tmp_file_dot)
    File.write!(tmp_file_svg, body)
    {:ok, c} = File.read(tmp_file_svg)

    # Earmark says that "A HTML Block defined by a tag starting a line
    # and the same tag starting a different line is parsed as one HTML
    # AST node, marked with %{verbatim: true}"
    # (see https://hexdocs.pm/earmark_parser/EarmarkParser.html )
    #
    # So we wrap everything in a DIV and call it a day.
    cx = "<div>\n\n#{c}\n\n</div>\n\n"

    {:ok, cx}
  end

  @doc """
  Computes a printable SHA for a string.
  """

  def string_hash(s),
    do:
      :crypto.hash(:sha, s)
      |> Base.encode16()
end
