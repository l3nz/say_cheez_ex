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

  @doc """
  Fun fun fun


  """

  def makeSomeSvgFun(v) do
    """
    <pre>#{v}</pre>

    <svg viewBox="0 0 100 100" preserveAspectRatio="xMidYMid slice" role="img">
      <title>A gradient</title>
      <linearGradient id="gradient">
        <stop class="begin" offset="0%" stop-color="red" />
        <stop class="end" offset="100%" stop-color="black" />
      </linearGradient>
      <rect x="0" y="0" width="100" height="100" style="fill:url(#gradient)" />
      <circle cx="50" cy="50" r="30" style="fill:url(#gradient)" />
    </svg>

    """
  end
end
