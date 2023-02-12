defmodule SayCheezEx do
  @moduledoc """
  Documentation for `SayCheezEx`.

        build_at: "230212-1413",
        build_at_day: "23-02-12",
        build_at_full: "23-02-12 14:13:03",
        build_by: "lenz",
        build_on: "integration03",
        build_version: "147",
        git_all: "c000dea/2023-02-12.13:07:31",
        git_commit_id: "c000dea",
        git_commit_long: "c000dea548c7c43e5f9ccfa17ff4897d87142d95",
        git_date: "2023-02-12.13:07:31",
        git_date_compact: "20230212-1307",
        git_last_committer: "Lenz",
        project_name: :say_cheez_ex,
        project_version: "0.1.0-dev",
        system: "1.13.4/OTP25",
        system_elixir: "1.13.4",
        system_otp: "25"


  """

  @now NaiveDateTime.local_now()
  @git_log ["log", "--oneline", "-n", "1"]

  @doc """
  Gets information


  """

  def info(:git_commit_id), do: git_run(@git_log ++ ["--pretty=%h"])
  def info(:git_commit_id_full), do: git_run(@git_log ++ ["--pretty=%H"])
  def info(:git_last_committer), do: git_run(@git_log ++ ["--pretty=%aN"])

  def info(:git_date),
    do: git_run(@git_log ++ ["--pretty=%cd", "--date=format:%Y-%m-%d.%H:%M:%S"])

  def info(:git_date_compact),
    do: git_run(@git_log ++ ["--pretty=%cd", "--date=format:%Y%m%d-%H%M"])

  def info(:git_all), do: "#{info(:git_commit_id)}/#{info(:git_date)}"

  def info(:project_name), do: Mix.Project.config()[:app]
  def info(:project_version), do: Mix.Project.config()[:version]
  def info(:build_at), do: Calendar.strftime(@now, "%y%m%d-%H%M")
  def info(:build_at_full), do: Calendar.strftime(@now, "%y-%m-%d %H:%M:%S")
  def info(:build_at_day), do: Calendar.strftime(@now, "%y-%m-%d")

  def info(:build_on), do: get_env("HOST")
  def info(:build_by), do: get_env("USER")
  def info(:build_version), do: get_env("VERSION")

  def info(:system_elixir), do: System.build_info()[:version]
  def info(:system_otp), do: System.build_info()[:otp_release]
  def info(:system), do: "#{info(:system_elixir)}/OTP#{info(:system_otp)}"

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
        :build_at,
        :build_at_full,
        :build_at_day,
        :build_on,
        :build_by,
        :build_version,
        :system_elixir,
        :system_otp,
        :system
      ])

  def all(lElems) do
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
        "UNKNOWN"
    end
  end

  @doc """
  Reads the first env variable  that is not empty.
  """

  def get_env(var) when is_binary(var), do: get_env([var])

  def get_env(lVars) when is_list(lVars) do
    lVars
    |> Enum.reduce_while("?", fn var, acc ->
      case System.get_env(var) do
        nil -> {:cont, acc}
        "" -> {:cont, acc}
        v when is_binary(v) -> {:halt, v}
      end
    end)
  end
end
