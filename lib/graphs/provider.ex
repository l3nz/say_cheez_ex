defmodule SayCheezEx.Graphs.Provider do
  @moduledoc """
  The interface for a graph provider.

  - checks if a such a provider is available, given the
    providers' own configuration
  - renders a graph to some HTML that can be embedded

  """

  @callback render(String.t()) :: {:ok, String.t()} | {:error, String.t()}

  @callback render!(String.t()) :: String.t()

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
  Given a recipe *recipe* for a graph, first tries a cache and
  then call a "builder" function to create it.

  So if the SVG was already generated, we load it from
  disk - if not, we build it again.


  ## Builder

  It returns {:ok, svg_text} or {:error, reason}
  that will be used to display a result.

  """

  def rebuild_if_needed(module, recipe, fnBuilder) do
    cache =
      case cached?(module, recipe) do
        {:miss} -> fnBuilder.(recipe)
        {:hit, result} -> {:cached, result}
      end

    case cache do
      {:error, e} ->
        with :ok <- IO.puts("Error: #{inspect(e)}") do
          {:error, e}
        end

      {:cached, v} ->
        {:ok, v}

      {:ok, v} ->
        with :ok <- write_to_cache(module, recipe, v) do
          {:ok, v}
        end
    end
  end

  @doc """
  Computes a printable SHA for a string.
  """

  def string_hash(s),
    do:
      :crypto.hash(:sha, s)
      |> Base.encode16()

  @spec file(:cache | :temp, binary(), binary()) :: binary
  @doc """
  Creates a file name for a temporary file.

  Ths may be a cache file or a proper temporary file.

  If you need mode than one file, you should encode it in
  the extensions.
  """

  def file(mode, hash, ext) do
    dir =
      case mode do
        :temp ->
          System.tmp_dir!()

        :cache ->
          with td <- "_build/img_cache/" do
            File.mkdir_p!(td)
            td
          end
      end

    filename = "SayCheezImg_#{hash}_#{ext}"
    Path.join(dir, filename)
  end

  @doc """
  The only significant advantage of this HTTP client is that
  it only uses things that are in Erlang itself.

  https://stackoverflow.com/questions/20108421/using-the-httpc-erlang-module-from-elixir

  """

  def trivial_http_get_client(url) do
    :inets.start()
    :ssl.start()

    # {:ok,
    #  {{'HTTP/1.1', 200, 'OK'},
    #   [{'cache-control', 'max-age=600'}, {'connection', 'keep-alive'}, {'date', 'Sun, 13 Aug 2023 13:36:44 GMT'}, {'via', '1.1 varnish'}, {'accept-ranges', 'bytes'}, {'age', '0'}, {'etag', '"64d2c230-62a1"'}, {'server', 'GitHub.com'}, {'vary', 'Accept-Encoding'}, {'content-length', '25249'}, {'content-type', 'text/html; charset=utf-8'}, {'expires', 'Sat, 12 Aug 2023 21:13:32 GMT'}, {'last-modified', 'Tue, 08 Aug 2023 22:31:12 GMT'}, {'access-control-allow-origin', '*'}, {'x-proxy-cache', 'MISS'}, {'x-github-request-id', '50FE:1E84:3A10F7B:3B910FF:64D7F3A4'}, {'x-served-by', 'cache-fra-eddf8230046-FRA'}, {'x-cache', 'HIT'}, {'x-cache-hits', '1'}, {'x-timer', 'S1691933804.488448,VS0,VE91'}, {'x-fastly-request-id', '33838028b664f07c1371417b9755ce55472c970a'}],
    #   '<!DOCTYPE html>\n<html xmlns="http://www.w3.org/1999/xhtml" lang="en">\n<head>\n  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n  <meta http-equiv="X-UA-Compatible" content="IE=edge" />\n  <meta name="description" content="Welcome to Elixir, a dynamic, functional language designed for building scalable and maintainable applications">\n  <title>The Elixir programming language</title>\n  <link href="https://elixir-lang.org/atom.xml" rel="alternate" title="Elixir\'s Blog" type="application/atom+xml" />\n  <link rel="stylesheet" type="text/css" href="/css/style.css" />\n  <link rel="stylesheet" type="text/css" href="/css/syntax.css" />\n  <link rel="stylesheet" href="/js/icons/style.css">\n  <!--[if lt IE 8]><!-->\n  <link rel="stylesheet" href="/js/icons/ie7/ie7.css">\n  <!--<![endif]-->\n  <meta name="viewport" content="width=device-width,initial-scale=1" />\n  <link rel="stylesheet" id="font-bitter-css" href="//fonts.googleapis.com/css?family=Bitter:400,700" type="text/css" media="screen" />\n  <link rel="shortcut icon" type="image/x-icon" href="/favicon.ico" />\n  <link rel="search" type="application/opensearchdescription+xml" title="elixir-lang.org" href="/opensearch.xml" />\n  <script defer data-domain="elixir-lang.org" src="https://plausible.io/js/plausible.js"></script>\n  <script defer src="//ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>\n  <script defer src="/js/index.js" type="text/javascript" charset="utf-8"></script>\n  <!-- Begin Jekyll SEO tag v2.8.0 -->\n<meta name="generator" content="Jekyll v3.9.3" />\n<meta property="og:title" content="elixir-lang.github.com" />\n<meta property="og:locale" content="en_US" />\n<meta name="description" content="Website for Elixir" />\n<meta property="og:description" content="Website for Elixir" />\n<link rel="canonical" href="https://elixir-lang.org/" />\n<meta property="og:url" content="https://elixir-lang.org/" />\n<meta property="og:site_name" content="elixir-lang.github.com" />\n<meta property="og:type" content="website" />\n<meta name="twitter:card" content="summary" />\n<meta property="twitter:title" content="elixir-lang.github.com" />\n<script type="application/ld+json">\n{"@context":"https://schema.org","@type":"WebSite","description":"Website for Elixir","headline":"elixir-lang.github.com","name":"elixir-lang.github.com","url":"https://elixir-lang.org/"}</script>\n<!-- End Jekyll SEO tag -->\n\n</head>\n\n<body class="home">\n  <div id="container">\n    <div class="wrap">\n    <div id="header">\n      <div id="branding">\n        <a id="site-title" href="/" title="Elixir" rel="Home">\n          <img class="logo" src="/images/logo/logo.png" alt="Elixir Logo" />\n        </a>\n      </div>\n\n      <div id="menu-primary" class="menu-container">\n        <ul id="menu-primary-items">\n          <li class="menu-item home"><a class="spec" href="/">Home</a></li>\n          <li class="menu-item install"><a class="spec" href="/install.html">Install</a></li>\n          <li class="menu-item learning"><a class="spec" href="/learning.html">Learning</a></li>\n          <li class="menu-item docs"><a class="spec" href="/docs.html">Docs</a></li>\n          <li class="menu-item getting-started"><a class="spec" href="/getting-started/introduction.html">Guides</a></li>\n          <li class="menu-item cases"><a class="spec" href="/cases.html">Cases</a></li>\n          <li class="menu-item blog"><a class="spec" href="/blog/">Blog</a></li>\n        </ul>\n      </div>\n    </div>\n\n    <div id="main">\n\n\n<div id="content">\n  <div class="hfeed">\n  <div class="hentry post">\n    <div class="entry-summary">\n      <h5>Elixir is a dynamic, functional language for building scalable and maintainable applications.</h5>\n\n      <p>Elixir runs on the Erlang VM, known for creating low-latency, distributed, and fault-tolerant systems. These capabilities and Elixir tooling allow developers to be productive in several domains, such as web development, embedded software, machine learning, data pipelines, and multimedia processing, across a wide range of industries.</p>\n\n      <p>Here is a peek:</p>\n\n<figure class="highl' ++ ...}}

    case :httpc.request(String.to_charlist(url)) do
      {:ok, {{_, _http_code, _}, _, body}} -> {:ok, "#{body}"}
      e -> {:error, e}
    end
  end

  @doc """
  Checks whether we have a file in our cache.

  If we do, we return its contents.
  """
  def cached?(module, recipe) do
    filename = cached_filename(module, recipe)

    if File.exists?(filename) do
      {:hit, File.read!(filename)}
    else
      {:miss}
    end
  end

  @doc """
  Write a file to its right cache.
  """
  def write_to_cache(module, recipe, contents) do
    filename = cached_filename(module, recipe)
    File.write!(filename, contents)
  end

  @doc """
  Generates a file name for a tuple (module, recipe).
  """

  def cached_filename(module, recipe) do
    hash = string_hash(recipe)
    file(:cache, hash, "#{module}.md")
  end

  @doc """
    Earmark says that "A HTML Block defined by a tag starting a line
    and the same tag starting a different line is parsed as one HTML
     AST node, marked with %{verbatim: true}"
     (see https://hexdocs.pm/earmark_parser/EarmarkParser.html )

     So we wrap everything in a DIV and call it a day.

  """
  def wrap_in_div_for_valid_markdown(s),
    do: "<div>\n\n#{s}\n\n</div>\n\n"

  @doc """
  We want to simplify the SVG that Graphviz generates
  so we can embed it in our HTML.

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

  @doc """
  Formats the error message, if any.
  """
  def display({:ok, markdown}), do: markdown

  def display({:error, msg}),
    do: """
    **Something went wrong**

    #{msg}

    """
end
