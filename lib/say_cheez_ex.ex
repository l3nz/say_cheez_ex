defmodule SayCheezEx do
  @moduledoc """
  This module is used to retrieve assorted pieces of
  configuration from a release's build environemnt.

  - Which build is this?
  - Who built this release?
  - When was this built?
  - What was the Git sha for this build?

  To use it, just add it to your `mix.exs`.

  Then capture all elements you need to a
  module attribute - e.g.

  ```
    module Foo do
      #  version: 0.1.1/7ea2260/230212.1425
      @version SayCheezEx.info(:project_full_version)

      ...
    end
  ```

  Data gatehring will be done at compile time and will
  simply create a string once and for all that matches
  your informational need.

  See `info/1` for  list of allowed attributes

  """

  @now NaiveDateTime.local_now()
  @git_log ["log", "--oneline", "-n", "1"]
  @unknown_entry "?"

  @doc """
  Gets assorted pieces of system information.

  ## Project

  -  project_name: "say_cheez_ex",
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
   - git_date_compact: "230212.1425" - she compact date of last commit
   - git_last_committer: "Lenz" - the author of last commit

  ## Build information

   - build_at: "230213.1545" - a short date of when the release was built
   - build_at_day: "2023-02-13" - the day a release was built
   - build_at_full: "2023-02-13.15:45:08" - the exact time a release was built
   - build_by: "jenkins"  - the user that was running on the build server
   - build_on: "intserver03" - the server the release was built on

  ### Jenkins-specific

   - build_number: "86" - the value of the `BUILD_NUMBER`





  """

  def info(:git_commit_id), do: git_run(@git_log ++ ["--pretty=%h"])
  def info(:git_commit_id_full), do: git_run(@git_log ++ ["--pretty=%H"])
  def info(:git_last_committer), do: git_run(@git_log ++ ["--pretty=%aN"])

  def info(:git_date),
    do: git_run(@git_log ++ ["--pretty=%cd", "--date=format:%Y-%m-%d.%H:%M:%S"])

  def info(:git_date_compact),
    do: git_run(@git_log ++ ["--pretty=%cd", "--date=format:%y%m%d.%H%M"])

  def info(:git_all), do: "#{info(:git_commit_id)}/#{info(:git_date_compact)}"

  def info(:project_name), do: Mix.Project.config()[:app]
  def info(:project_version), do: Mix.Project.config()[:version]
  def info(:project_full_version), do: "#{info(:project_version)}/#{info(:git_all)}"
  def info(:build_at), do: Calendar.strftime(@now, "%y%m%d.%H%M")
  def info(:build_at_full), do: Calendar.strftime(@now, "%Y-%m-%d.%H:%M:%S")
  def info(:build_at_day), do: Calendar.strftime(@now, "%Y-%m-%d")

  def info(:build_on), do: get_env("HOST")
  def info(:build_by), do: get_env("USER")
  def info(:build_number), do: get_env("BUILD_NUMBER")

  def info(:system_elixir), do: System.build_info()[:version]
  def info(:system_otp), do: System.build_info()[:otp_release]
  def info(:system), do: "#{info(:system_elixir)}/OTP#{info(:system_otp)}"

  @doc """
  Dumps a map of all known build/env configuration
  keys for this environment.

  If you want a map of only some elements, see
  `all/1`.
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

  @doc """
  Prints a map of only some elements.

  If you want a map of all elements, see
  `all/0`.


  """
  def all(lElems) when is_list(lElems) do
    lElems
    |> Enum.map(fn k -> {k, info(k)} end)
    |> Map.new()
  end

  @doc """
  Runs GIT.
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
  Reads the first env variable  that is not empty.
  """

  def get_env(var) when is_binary(var), do: get_env([var])

  def get_env(lVars) when is_list(lVars) do
    lVars
    |> Enum.reduce_while(@unknown_entry, fn var, acc ->
      case System.get_env(var) do
        nil -> {:cont, acc}
        "" -> {:cont, acc}
        v when is_binary(v) -> {:halt, v}
      end
    end)
  end
end
