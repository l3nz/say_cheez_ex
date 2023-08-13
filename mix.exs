defmodule SayCheezEx.MixProject do
  use Mix.Project

  @source_url "https://github.com/l3nz/say_cheez_ex"
  @version "0.3.3"

  def project do
    [
      app: :say_cheez_ex,
      version: @version,
      description: "Captures the environment 📸 at build time and embeds graphs in ExDocs",
      package: package(),
      dialyzer: dialyzer(),
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:mimic, "~> 1.7", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package do
    [
      maintainers: ["lenz"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(.formatter.exs mix.exs README.md CHANGELOG.md lib)
    ]
  end

  # We have to add Mix in
  defp dialyzer do
    [
      plt_add_apps: [:mix],
      plt_add_deps: [:mix]
    ]
  end

  defp docs do
    [
      # The main page in the docs, è il nome lowercase di una pagina
      main: "readme",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"],
      authors: ["LE"],
      formatters: ["html"],
      before_closing_body_tag: fn
        :html ->
          """
          <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
          <script>mermaid.initialize({startOnLoad: true})</script>
          """

        _ ->
          ""
      end
    ]
  end

  defp aliases do
    [
      setup: ["cmd rm -rf ./_build", "clean", "deps.get"],
      check: ["format", "credo", "dialyzer"]
    ]
  end
end
