defmodule SayCheezEx do
  @moduledoc """
  This module is used to retrieve assorted pieces of
  configuration from a release's build environment.

  - Which build is this?
  - Who built this release?
  - When was this built?
  - What was the Git sha for this build?

  Make sure that you capture all elements you need to a
  module attribute - e.g.

  ```
    module Foo do
      #  version: 0.1.1/7ea2260/230212.1425
      @version SayCheezEx.info(:project_full_version)

      ...
    end
  ```

  Data gathering **must** be  done at compile time and will
  simply create a string once and for all that matches
  your informational need.

  See `info/1` for  list of allowed attributes, or `all/0` for
  a map with all pre-defined attributes.

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
   - build_on: "intserver03" - the server the release was built on

  ### Jenkins-specific

   - build_number: "86" - the value of the `BUILD_NUMBER` attribute





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

  def info(:build_on), do: get_env_log("HOST")
  def info(:build_by), do: get_env_log("USER")
  def info(:build_number), do: get_env_log("BUILD_NUMBER")

  def info(:system_elixir), do: System.build_info()[:version]
  def info(:system_otp), do: System.build_info()[:otp_release]
  def info(:system), do: "#{info(:system_elixir)}/OTP#{info(:system_otp)}"

  @spec all :: map
  @doc """
  Dumps a map of all known build/env configuration
  keys for this environment.

  If you want a map of only some elements, see
  `all/1`.

  An example output might be:

  ````
  %{
    build_at: "230213.1617",
    build_at_day: "2023-02-13",
    build_at_full: "2023-02-13.16:17:55",
    build_by: "lenz",
    build_number: "?",
    build_on: "?",
    git_all: "8c0449f/230213.1621",
    git_commit_id: "8c0449f",
    git_commit_id_full: "8c0449fdffc5da6f68237ce8d542ae69ac268cad",
    git_date: "2023-02-13.16:21:12",
    git_date_compact: "230213.1621",
    git_last_committer: "Lenz",
    project_full_version: "0.1.0-dev/8c0449f/230213.1621",
    project_name: :say_cheez_ex,
    project_version: "0.1.0-dev",
    system: "1.13.4/OTP25",
    system_elixir: "1.13.4",
    system_otp: "25"
  }
  ````


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
        :system_elixir,
        :system_otp,
        :system
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

  def git_run(subcmd) when is_list(subcmd) do
    case System.cmd("git", subcmd) do
      {tag, 0} ->
        String.trim(tag)

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
  TO BE DONE.


  SayCheezEx.msg(["Hello ", :system, " how are you?" ])



  """
  def msg(tokens) when is_list(tokens) do
    tokens
    |> Enum.map_join(fn
      t when is_binary(t) -> t
      k when is_atom(k) -> info(k)
      e when is_list(e) -> get_env(e)
    end)
  end

  @doc """
  Creates a date out of an ISO date.

  We need to do this instead of giving git format options,
  as date formatting is not supported well by ancient git
  versions (e.g. Centos7 still has git 1.8).

  So we basically break a date of the format `2023-02-15 08:50:19 +0100`
  into a set of tonkens, and reassemble them based on a list of input
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
end
