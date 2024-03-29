defmodule SayCheezEx do
  alias SayCheezEx.DataSource.Beam
  alias SayCheezEx.Graphs.Graphviz
  alias SayCheezEx.Graphs.Plantuml

  @moduledoc """
  This module is used to retrieve assorted pieces of
  configuration from a release's build environment.

  - Which build is this?
  - Who built this release?
  - When was this built?
  - What was the Git SHA for this build?

  # Usage

  Make sure that you capture all elements you need to a
  module attribute - e.g.

  ```
    module Foo do
      import SayCheezEx, only: [cheez!: 1]
      # e.g. "v 0.1.5/d9a87c3 137 on server.local"
      @version cheez!("v {:project_version}/{:git_commit_id} {:build_number} on {:build_on}")
      ...
    end
  ```

  Data gathering **must** be  done at compile time and will
  simply create a string once and for all that matches
  your informational need.

  This can be done in multiple ways:

  - You can call the `cheez!/1` or `cheez/1` functions with a format
    string, as described in their docs
  - You can call `info/1` and `get_env/1` to extract the specific
    parameters you need.

  See `info/1` for  list of allowed attributes, or `all/0` for
  a map with all pre-defined attributes.

  # Graphs

  What is better than Elixir's own documentation? adding
  graphs to it, and having them embedded in your documentation.

  To try them, use:

  ```
    module Foo do
      import SayCheezEx, only: [uml: 1, graphviz: 1]

      @moduledoc "\""
      Here goes a Graphviz graph:

      \#{graphviz("digraph { Sup -> GenServ }")}

      Here a PlantUML graph:

      \#{uml("\""
        Bob -> Alice : I do love UML in documentation
        Alice -> Bob : I love it too!
      \""")}

      "\""

      ...
    end
  ```

  See for yourself some examples at:

  - `graphviz/1`
  - `uml/1`

  Graphs are cached under `_build/img_cache` so a full
  render happens only when they change.

  """

  @now NaiveDateTime.local_now()
  @git_log ["log", "--oneline", "-n", "1"]
  @unknown_entry "?"

  @spec info(atom) :: binary
  @doc """
  Gets assorted pieces of system information.

  ## Project

  -  project_name: "SayCheezEx" - the project will be named with an atom
     as `:say_cheez_ex`, but we return a camelized string
  -  project_version: "0.1.0-dev",
  - project_full_version:  "0.1.0-dev/7ea2260/230212.1425",

  ### Elixir - Erlang

  - system: "1.13.4/OTP25",
  - system_elixir: "1.13.4",
  - system_otp: "25"

  ## Git

   - git_all: "7ea2260/230212.1425" - a
     recap of commit id and date compact
   - git_commit_id: "7ea2260" - the short commit-id
   - git_commit_id_full: "7ea2260895f35fc46976a2fdbc4d8faeaad09467" -  the full commit-id
   - git_date: "2023-02-12.14:25:47" - the date if last commit
   - git_date_compact: "230212.1425" - the compact date of last commit
   - git_last_committer: "Lenz" - the author of last commit

  ## Build information

   - build_at: "230213.1545" - a short date of when the release was built
   - build_at_day: "2023-02-13" - the day a release was built
   - build_at_full: "2023-02-13.15:45:08" - the exact time a release was built
   - build_by: "jenkins"  - the user that was running on the build server
   - build_on: "intserver03" - the server the release was built on.
     First checks `hostname` then the environment variable `HOST`
   - `build_mix_env`: the mix build environament, as a string (e.g. _"dev"_ or _"prod"_)

  ### Jenkins-specific

   - build_number: "86" - the value of the `BUILD_NUMBER` attribute

  ### System environment

    - `sysinfo_arch`: the system architecture  (e.g. _"aarch64-apple-darwin22.3.0"_)
    - `sysinfo_beam`: the type of VM, whether it's a JIT or interpreter, and its version (e.g. _"BEAM jit 13.2"_)
    - `sysinfo_banner`: the "welcome banner" that the VM prints on startup (e.g. _"Erlang/OTP 25 [erts-13.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]"_)
    - `sysinfo_c_compiler`: the system C compiler used to build the VM  (e.g. _"gnuc 4.2.1"_)
    - `sysinfo_compat`: the Erlang/OTP release that the current emulator has been set to be backward compatible with  (e.g. _"25"_)
    - `sysinfo_driver`: Erlang driver version used by the runtime system (e.g. _"3.3"_)
    - `sysinfo_nif`: version of the Erlang NIF interface (e.g. _"2.16"_)
    - `sysinfo_ptr`: the size of Erlang term words in bits (e.g. _"64bit"_)
    - `sysinfo_word`: the size of an emulator pointer in bits (e.g. _"64bit"_)

  """

  def info(:git_commit_id), do: git_run(@git_log ++ ["--pretty=%h"])
  def info(:git_commit_id_full), do: git_run(@git_log ++ ["--pretty=%H"])
  def info(:git_last_committer), do: git_run(@git_log ++ ["--pretty=%aN"])

  def info(:git_date),
    do:
      git_iso_date()
      |> date_from_iso_date([:ce, :yy, "-", :mm, "-", :dd, ".", :h, ":", :m, ":", :s])

  def info(:git_date_compact),
    do:
      git_iso_date()
      |> date_from_iso_date([:yy, :mm, :dd, ".", :h, :m])

  def info(:git_all), do: "#{info(:git_commit_id)}/#{info(:git_date_compact)}"

  def info(:project_name),
    do:
      Mix.Project.config()[:app]
      |> Atom.to_string()
      |> Macro.camelize()

  def info(:project_version), do: Mix.Project.config()[:version]
  def info(:project_full_version), do: "#{info(:project_version)}/#{info(:git_all)}"
  def info(:build_at), do: Calendar.strftime(@now, "%y%m%d.%H%M")
  def info(:build_at_full), do: Calendar.strftime(@now, "%Y-%m-%d.%H:%M:%S")
  def info(:build_at_day), do: Calendar.strftime(@now, "%Y-%m-%d")

  def info(:build_on),
    do: first_non_empty([hostname(), get_env("HOST")])

  def info(:build_by), do: get_env("USER")

  def info(:build_number),
    do: first_non_empty([get_env("BUILD_NUMBER"), get_env("BUILD_N")])

  def info(:build_mix_env),
    do: "#{Mix.env()}"

  def info(:system_elixir), do: Beam.build_info()[:version]
  def info(:system_otp), do: Beam.build_info()[:otp_release]
  def info(:system), do: "#{info(:system_elixir)}/OTP#{info(:system_otp)}"

  def info(:sysinfo_beam),
    do:
      "#{Beam.system_info(:machine)} #{Beam.system_info(:emu_flavor)} #{Beam.system_info(:version)}"

  def info(:sysinfo_word), do: "#{Beam.system_info({:wordsize, :internal}) * 8}bit"
  def info(:sysinfo_ptr), do: "#{Beam.system_info({:wordsize, :external}) * 8}bit"
  def info(:sysinfo_nif), do: "#{Beam.system_info(:nif_version)}"

  def info(:sysinfo_c_compiler),
    do:
      Beam.system_info(:c_compiler_used)
      |> format_sysinfo_c_compiler()

  def info(:sysinfo_compat), do: "#{Beam.system_info(:compat_rel)}"
  def info(:sysinfo_driver), do: "#{Beam.system_info(:driver_version)}"
  def info(:sysinfo_arch), do: "#{Beam.system_info(:system_architecture)}"
  def info(:sysinfo_banner), do: "#{Beam.system_info(:system_version)}" |> String.trim()

  def info(_), do: @unknown_entry

  @doc """
  As the C compiler is formatted differently on Win and Unix,
  we handle both cases with a related unit test, so we can add (and test) more.

  """
  def format_sysinfo_c_compiler({cc, v}) when is_tuple(v),
    do: format_sysinfo_c_compiler({cc, tuple_to_dotted(v)})

  def format_sysinfo_c_compiler({cc, v}), do: "#{cc} #{v}"

  defp tuple_to_dotted(t),
    do:
      t
      |> Tuple.to_list()
      |> Enum.join(".")

  @spec all :: map
  @doc """
  Dumps a map of all known build/env configuration
  keys for this environment.

  If you want a map of only some elements, see
  `all/1`.

  An example output might be:

  ````
  %{
    build_at: "230411.1528",
    build_at_day: "2023-04-11",
    build_at_full: "2023-04-11.15:28:47",
    build_by: "lenz",
    build_number: "87",
    build_on: "Lenzs-MacBook-Pro.local",
    build_mix_env: "dev",
    git_all: "b204919/230411.1509",
    git_commit_id: "b204919",
    git_commit_id_full: "b2049190312ef810875476398978c2b0387251d3",
    git_date: "2023-04-11.15:09:50",
    git_date_compact: "230411.1509",
    git_last_committer: "Lenz",
    project_full_version: "0.2.1/b204919/230411.1509",
    project_name: "SayCheezEx",
    project_version: "0.2.2",
    sysinfo_arch: "aarch64-apple-darwin22.3.0",
    sysinfo_beam: "BEAM jit 13.2",
    sysinfo_c_compiler: "gnuc 4.2.1",
    sysinfo_compat: "25",
    sysinfo_driver: "3.3",
    sysinfo_nif: "2.16",
    sysinfo_ptr: "64bit",
    sysinfo_word: "64bit",
    system: "1.14.3/OTP25",
    system_elixir: "1.14.3",
    system_otp: "25",
    ...
  }
  ````

  but the right place to check all properties and their meaning is `info/1`.


  """
  def all(),
    do:
      all([
        :git_commit_id,
        :git_commit_id_full,
        :git_last_committer,
        :git_date,
        :git_date_compact,
        :git_all,
        :project_name,
        :project_version,
        :project_full_version,
        :build_at,
        :build_at_full,
        :build_at_day,
        :build_on,
        :build_by,
        :build_number,
        :build_mix_env,
        :system_elixir,
        :system_otp,
        :system,
        :sysinfo_beam,
        :sysinfo_word,
        :sysinfo_ptr,
        :sysinfo_nif,
        :sysinfo_c_compiler,
        :sysinfo_compat,
        :sysinfo_driver,
        :sysinfo_arch,
        :sysinfo_banner
      ])

  @spec all(maybe_improper_list) :: map
  @doc """
  Prints a map of only some elements.

  If you want a map of all elements, see
  `all/0`.


  """
  def all(elems) when is_list(elems) do
    elems
    |> Enum.map(fn k -> {k, info(k)} end)
    |> Map.new()
  end

  @spec git_run([binary]) :: binary
  @doc """
  Runs current Git command.

  CWD is the root of the repo.
  """

  def git_run(subcmd), do: run_cmd("git", subcmd)

  @doc """
  Reads a hostname.
  """
  def hostname(), do: run_cmd("hostname", [])

  @doc """
  Runs a command.

  Returns the output, only if return code is zero.

  Otherwise returns "@unknown_entry"
  """
  def run_cmd(cmd, parameters) when is_list(parameters) do
    case System.cmd(cmd, parameters) do
      {result, 0} ->
        String.trim(result)

      _ ->
        @unknown_entry
    end
  end

  @doc """
  Reads an ISO date from Git.

  See `date_from_iso_date/2`
  """
  def git_iso_date(),
    do: git_run(@git_log ++ ["--pretty=%cd", "--date=iso"])

  @spec get_env(binary | maybe_improper_list) :: binary
  @doc """
  Reads the first env variable  that is not empty.
  """

  def get_env(var) when is_binary(var), do: get_env([var])

  def get_env(vars) when is_list(vars) do
    vars
    |> Enum.reduce_while(@unknown_entry, fn var, acc ->
      case System.get_env(var) do
        nil -> {:cont, acc}
        "" -> {:cont, acc}
        v when is_binary(v) -> {:halt, v}
      end
    end)
  end

  def get_env_log(var) do
    case get_env(var) do
      @unknown_entry ->
        with all_env <- System.get_env() do
          IO.puts("=== Could not find environment variable #{inspect(var)}")
          IO.puts("Current environment:")

          for {k, v} <- all_env do
            IO.puts(" - #{k} = '#{v}'")
          end

          @unknown_entry
        end

      s ->
        s
    end
  end

  @doc """
  Given a list of candidates, returs the first that
  is not unknown.

  If all of them are unknown, return the default.

  """

  def first_non_empty(vars, def_val \\ @unknown_entry)
      when is_list(vars) and is_binary(def_val) do
    vars
    |> Enum.filter(fn v -> v != @unknown_entry end)
    |> List.first(def_val)
  end

  @doc """
  Tokenizes a string into a list.




  """

  def tokenize(s, env \\ [])
  def tokenize("", env), do: env

  def tokenize(s, env) do
    case Regex.run(~r/^(.*?)\{(.+?)\}(.*)$/, s) do
      [_, text, tokens, rest] ->
        tokenize(rest, env ++ [text, tokenize_kws(tokens)])

      _ ->
        env ++ [s]
    end
  end

  @doc """
  Breaks up a list of keywords into tuples.

  """
  def tokenize_kws(kws) do
    kws
    |> String.split(~r/,/)
    |> Enum.map(fn kw ->
      case Regex.run(~r/^(.)(.+)$/, kw) do
        [_, "$", v] -> {:env, v}
        [_, ":", v] -> {:kw, String.to_atom(v)}
        [_, "=", v] -> {:default, v}
      end
    end)
  end

  @doc """
  Expands a sequence of tokens into a string.
  """

  def expand(tokenized_seq) do
    tokenized_seq
    |> Enum.map_join(fn
      i when is_binary(i) ->
        i

      l when is_list(l) ->
        l
        |> Enum.map(fn
          {:kw, a} -> info(a)
          {:env, e} -> get_env(e)
          {:default, e} -> e
        end)
        |> first_non_empty()
    end)
  end

  @doc """
  We want to rewrite ELixir module names so we can remove
  the Elixir prefix.

  From

      "{:abc,=NONE} Elixir.My.Module {:abc,=NONE}"

  To

      "{:abc,=NONE} My.Module {:abc,=NONE}"


  """
  def replace_elixir_modules(s), do: Regex.replace(~r/Elixir\.([[:upper:]])/, s, "\\g{1}")

  @doc """
  Captures the environment from a definition string.

  Same as `cheez!/1` but it does not print the
  captured string.

  """
  def cheez(s) when is_binary(s),
    do:
      s
      |> replace_elixir_modules()
      |> tokenize()
      |> expand()

  @doc """
  Captures the environment from a definition string, and
  prints it out so it is shown in the compile logs.

  Usage:

        > cheez!("v {:project_version}/{:git_commit_id} {:build_number} on {:build_on}")
        "v 0.1.5/d9a87c3 137 on server.local"

  ## Definition strings



  This function will **interpolate attributes** set
  between brackets, with the following rules:

  - `{:project_version}` is an info tag. These is a long
   list of those - see `all/0`.
  - `{$HOST}` is an environment variable - in this case, HOST
  - `{=HELLO}` is a default value, in this case the literal string "HELLO"

  If multiple attributes are specified in a comma-separated string,
   they all are expanded,
  and the first one that is defined will be output. So e.g.
  `{$FOO,$BAR,=BAZ}` will first try to interpolate the variable FOO;
  if that is undefined, it will try BAR, and if that too is undefined,
  it will output "BAZ" (that is always defined)


  As it is quite a common thing to include a **module name** in the
  string as it appears in the __MODULE__ attribute, and that will
  print out the module with an "Elixir" prefix (e.g. module "Foo.Bar"
  will become "Elixir.Foo.Bar"), the "Elixir" prefix is stripped
  when found.

  ## Controlling output

  In general, on every capture, we would love to print out the current captured
  variables on STDOUT. This is quite handy for server builds,
  as in the build log there are the same pieces of information
  that the build embeds.

  This also gets in the way during development and testing,
  cluttering the output.

  So the default is that is printing only happens when building
  in the `:prod` environment, unless you force it on or off
  using the CHEEZ environment variable. So, say....

        CHEEZ=1 mix test

  Will print captured output (see `should_print?/0` for further
  details). Of course this only happens when compiling classes,
  so when working interactively you may sometimes see the output
  and sometimes won't, as the compiler decides what is in
  need of being rebuilt.

  If you don't want this fuction to print out the captured
  environment, just use `cheez/1`.

  """

  def cheez!(s) when is_binary(s) do
    cs = cheez(s)

    if should_print?() do
      IO.puts("-- 📸 '#{cs}'")
    end

    cs
  end

  @doc """
  Creates a date out of an ISO date.

  We need to do this instead of giving git format options,
  as date formatting is not supported well by ancient git
  versions (e.g. Centos7 still has git 1.8).

  So we basically break a date of the format `2023-02-15 08:50:19 +0100`
  into a set of tokens, and reassemble them based on a list of input
  tokens or constant strings.

  """

  def date_from_iso_date(iso_date, fmt_list) when is_binary(iso_date) and is_list(fmt_list) do
    dt =
      case Regex.run(~r/^(\d\d)(\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/, iso_date) do
        [_, ce, yy, mm, dd, h, m, s] -> %{ce: ce, yy: yy, mm: mm, dd: dd, h: h, m: m, s: s}
        _ -> %{}
      end

    fmt_list
    |> Enum.map_join(fn
      t when is_atom(t) -> Map.get(dt, t, "?")
      s when is_binary(s) -> s
    end)
  end

  @doc """
  Checks whether we should output the results of SayCheezEx on
  STDOUT.

  In a separate function for ease of testing.

  """
  def should_print?(env_cheez, build_mix_env) do
    case env_cheez do
      "1" ->
        true

      "0" ->
        false

      _ ->
        case build_mix_env do
          "prod" -> true
          _ -> false
        end
    end
  end

  @doc """
  When should we print on STDOUT?

  - in environment `:prod` only (so for final build)
  - unless environment variable `CHEEZ` is set to 1, that forces printing
    in all environments
  - unless environment variable `CHEEZ` is set to 0, that silences printing
    in all environments


  """
  def should_print?(),
    do: should_print?(get_env("CHEEZ"), info(:build_mix_env))

  @doc """
  Runs a local Graphviz command and embeds the resulting SVG.

  #{Graphviz.render!("""
  digraph {
    Sup -> GenServ;
    Sup -> OtherGenServer;
  }
  """)}


  ## Notes

  - Requires GraphViz installed
  - You can find full documentation of GraphViz at
    https://graphviz.org/
  - See also `uml/1`.


  """

  def graphviz(s), do: Graphviz.render!(s)

  @doc """
  Runs a command though PlantUml, either local or on-line.

  This is pretty handy to document, for example, a set of GenServers
  and how they depend on each other:

  #{Plantuml.render!("""
      Component [Application] as C #Yellow
      Component [Pool] as P #Yellow
      Component [Activator] as A
      Component [Logger] as LOG


      cloud "QMLive" {
      Component [QML]
      }

      Component [Web acceptor] as WA #Yellow



      database "Local DB" {
      Component [Table of Services] as TSVC
      Component [Instance state] as TIS
      }

      TSVC --> A

      C .. A
      C .. P
      A -> P
      C .. LOG



      frame "Operator 1" {
      Component [Operator 1] as S
      Component [Updater] as SU
      Component [DynamicSupervisor] as DS #White

      QML <.. SU
      TIS <.. SU
      SU -> DS


      P --> S

      S ..> SU
      S ..> DS


      Component [Puller X] as PX
      Component [Puller Y] as PY

      Component [Pusher A] as IA
      Component [Pusher B] as IB

      Component [Cmds A] as CA


      WA --> PX
      WA --> CA
      DS .. [PX]
      DS .. [PY]
      DS .. [IA]
      DS .. [IB]
      DS .. [CA]

      PX --> IA
      PX --> IB

      }




      frame "Operator N" {
      Component [Service N] as SN
      }

      P --> [SN]

  """)}




  Or how multiple GenServers send messages to each other and
  which responses/replies are used:

  #{Plantuml.render!("""

    title "Shared feedback actions"

    participant PBX

    participant Uniloader as U


    box "LogFwd" #white
    entity "Puller" as PU #red

    entity "Pusher 1" as F1 #yellow
    entity "Commands 1" as  C1 #yellow


    entity "Pusher 2" as F2 #pink
    entity "Commands 2" as  C2 #pink

    end box

    participant "QMLive 1" as Q1 #yellow
    participant "QMLive 2" as Q2 #pink

    activate F1
    F1 --> Q1 ++: Log upload...
    Q1 --> F1 --: Actions pending
    F1 --> C1: Check actions
    deactivate F1
    activate C1
    |||

    C1 --> Q1 ++ : Any news?
    Q1 --> C1 -- : new command,\\n id=123
    C1  --> PU ++ : new cmd,\\n id=C1/P1/123
    deactivate C1
    note over PU: Command stored

    |||
    C2 -> C2 ++: Timer wake-up
    C2 --> Q2 ++ : Any news?
    Q2 --> C2 -- : "new command, id=42"
    C2 --> PU : "new cmd, id=C2/P1/42"
    deactivate C2
    note over PU: 2 cmds stored
    |||

    PU -> U
    U -> PBX

  """)}


  And there is way more - only limited by your imagination.
  For example, this is a mind-map (stolen from https://www.drawio.com/blog/plantuml-mindmaps-from-text)
  It ain't' half bad, right?

  #{Plantuml.render!("""

  @startmindmap
  caption Tasks
  title Onboarding and offboarding tasks

  +[#lightgreen] Onboarding
  ++ Prior to first day
  +++_ <&star>Contract signed
  +++_ Employee handbook
  +++_ IT equipment reserved
  ++ First day
  +++_ <&people>Office tour
  +++_ <&people>Team intros
  +++ Account setup
  ++ First week
  +++_ <&people>Shadow team members
  +++_ Software training
  ++ First month
  +++_ Assign projects/tasks
  +++_ Set goals
  +++_ <&people>Get team feedback

  +[#orange] Offboarding
  ++ <&people>Feedback and review
  ++[#999999] <s>Exit interview</s>
  ++ Tasks/projects reassigned
  +++_ <&people>Handover
  ++ Account deactivation/deletion
  ++ IT hardware return

  header
  Currently under review
  endheader

  legend right
    <&star> priority
    <&people> meetings
  endlegend

  center footer Last updated: May
  @endmindmap
  """)}

  And as all of this is text-based, it plays well with your source
  files, version control and whatnot.

  ## Notes

  - You can find full documentation of PlantUML and the
    gazillion graphs it produces at https://plantuml.com/
  - At the moment, all images are processed through
    the on-line server
  - Nothing stops you from using the module `SayCheezEx.Graphs.Plantuml` to generate
    SVG images at runtime, not only in documentation.
  - See also `graphviz/1`.


  """

  def uml(s), do: Plantuml.render!(s)
end
