defmodule SayCheezEx.DataSource.Beam do
  @moduledoc """
  Reads information out of the Elixir / Beam environment.

  Set into a special module for ease of testing via mocking.

  """

  @doc """
  Calls `:erlang.system_info/1`.

  """

  def system_info(v), do: :erlang.system_info(v)

  @doc """
  Calls `System.build_info()`.


  E.g.

        %{
          build: "1.14.3 (compiled with Erlang/OTP 25)",
          date: "2023-01-14T15:30:14Z",
          otp_release: "25x",
          revision: "6730d66",
          version: "1.14.2"
        }

  """
  def build_info(), do: System.build_info()
end
