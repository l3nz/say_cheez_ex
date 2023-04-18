defmodule SayCheezExTest do
  # mix test test/say_cheez_ex_test.exs
  use ExUnit.Case, async: true
  use Mimic
  doctest SayCheezEx

  @moduledoc """
  Most of these things are rather hard to test.
  """

  def date_matches?(date, regex_templ) do
    {:ok, rx} =
      "^#{regex_templ}$"
      |> String.replace("n", "\\d")
      |> String.replace(".", "\\.")
      |> Regex.compile()

    case String.match?(date, rx) do
      true -> :ok
      _ -> {:nomatch, date, regex_templ, rx}
    end
  end

  describe "git integration:" do
    test "parse dates" do
      dt = "2023-02-15 08:50:19 +0100"

      assert "2023-15" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:ce, :yy, "-", :dd]
               )

      assert "230215.0850" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:yy, :mm, :dd, ".", :h, :m]
               )

      assert "2023-02-15.08:50:19" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:ce, :yy, "-", :mm, "-", :dd, ".", :h, ":", :m, ":", :s]
               )

      assert "2302?.0850" =
               SayCheezEx.date_from_iso_date(
                 dt,
                 [:yy, :mm, :zebra, ".", :h, :m]
               )
    end

    test "dates" do
      assert :ok =
               SayCheezEx.info(:git_date)
               |> date_matches?("nnnn-nn-nn.nn:nn:nn")

      assert :ok =
               SayCheezEx.info(:git_date_compact)
               |> date_matches?("nnnnnn.nnnn")
    end
  end

  describe "build info:" do
    test "dates" do
      assert :ok =
               SayCheezEx.info(:build_at)
               |> date_matches?("nnnnnn.nnnn")

      assert :ok =
               SayCheezEx.info(:build_at_full)
               |> date_matches?("nnnn-nn-nn.nn:nn:nn")

      assert :ok =
               SayCheezEx.info(:build_at_day)
               |> date_matches?("nnnn-nn-nn")
    end
  end

  describe "Other variables:" do
    test "camelized project name" do
      # in mix.exs, it is :say_cheez_ex
      assert "SayCheezEx" = SayCheezEx.info(:project_name)
    end

    test "Derived from System.build_info:" do
      SayCheezEx.DataSource.Beam
      |> stub(:build_info, fn ->
        %{
          build: "1.14.3 (compiled with Erlang/OTP 25)",
          date: "2023-01-14T15:30:14Z",
          otp_release: "25x",
          revision: "6730d66",
          version: "1.14.2"
        }
      end)

      assert "25x" = SayCheezEx.info(:system_otp)
      assert "1.14.2" = SayCheezEx.info(:system_elixir)
      assert "1.14.2/OTP25x" = SayCheezEx.info(:system)
    end

    test "mix env" do
      assert "test" = SayCheezEx.info(:build_mix_env)
    end

    test "from :erlang.info()" do
      SayCheezEx.DataSource.Beam
      |> stub(:system_info, fn
        {:wordsize, :internal} ->
          8

        {:wordsize, :external} ->
          8

        :nif_version ->
          '2.16'

        :c_compiler_used ->
          {:gnuc, {4, 2, 1}}

        :compat_rel ->
          25

        :driver_version ->
          '3.3'

        :system_architecture ->
          'aarch64-apple-darwin22.3.0'

        :system_version ->
          'Erlang/OTP 25 [erts-13.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]\n'

        :machine ->
          'BEAM'

        :emu_flavor ->
          :jit

        :version ->
          '13.2'
      end)

      assert "BEAM jit 13.2" = SayCheezEx.info(:sysinfo_beam)
      assert "64bit" = SayCheezEx.info(:sysinfo_word)
      assert "64bit" = SayCheezEx.info(:sysinfo_ptr)
      assert "2.16" = SayCheezEx.info(:sysinfo_nif)
      assert "gnuc 4.2.1" = SayCheezEx.info(:sysinfo_c_compiler)
      assert "25" = SayCheezEx.info(:sysinfo_compat)
      assert "3.3" = SayCheezEx.info(:sysinfo_driver)
      assert "aarch64-apple-darwin22.3.0" = SayCheezEx.info(:sysinfo_arch)

      assert "Erlang/OTP 25 [erts-13.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]" =
               SayCheezEx.info(:sysinfo_banner)
    end

    test "sysinfo_c_compiler" do
      assert "gnuc 4.2.1" = SayCheezEx.format_sysinfo_c_compiler({:gnuc, {4, 2, 1}})
      assert "msc 1926" = SayCheezEx.format_sysinfo_c_compiler({:msc, 1926})
    end
  end

  describe "Environment variables:" do
    test "finds first env variable" do
      System.put_env("X1", "10")
      System.put_env("X2", "20")

      assert "10" = SayCheezEx.get_env(["XA", "X1", "X2"])
      assert "20" = SayCheezEx.get_env(["XA", "XB", "X2"])
      assert "?" = SayCheezEx.get_env(["XA", "XB", "XC"])

      assert "10" = SayCheezEx.get_env("X1")
      assert "20" = SayCheezEx.get_env("X2")
      assert "?" = SayCheezEx.get_env("XXX")
    end
  end

  test "first non empty" do
    e = "?"
    assert "x" = SayCheezEx.first_non_empty([e, e, "x", "y", e])

    assert "k" = SayCheezEx.first_non_empty([], "k")
  end

  describe "fn cheez:" do
    test "cheez()" do
      assert :ok =
               SayCheezEx.cheez("x {:build_at}")
               |> date_matches?("x nnnnnn.nnnn")
    end

    test "remove Elixir prefix" do
      assert "NONE SayCheezExTest NONE" =
               SayCheezEx.cheez("{:abc,=NONE} #{__MODULE__} {:abc,=NONE}")
    end

    test "cheez!()" do
      assert :ok =
               SayCheezEx.cheez!("x {:build_at}")
               |> date_matches?("x nnnnnn.nnnn")
    end
  end

  describe "Tokenizer" do
    test "Plain" do
      assert [
               "v1 ",
               [{:kw, :abc}],
               "-",
               [{:env, "DE"}, {:kw, :fg}],
               "!"
             ] = SayCheezEx.tokenize("v1 {:abc}-{$DE,:fg}!")
    end

    test "No tokens" do
      assert [
               "v1"
             ] = SayCheezEx.tokenize("v1")
    end

    test "Just a token" do
      assert [
               "",
               [{:kw, :abc}]
             ] = SayCheezEx.tokenize("{:abc}")
    end

    test "Expander" do
      System.put_env("EA", "10")

      assert "a: ? - b: 10" =
               SayCheezEx.tokenize("a: {:abc} - b: {$EB,$EA}")
               |> SayCheezEx.expand()
    end

    test "Expander with defaults" do
      assert "a: NONE" =
               SayCheezEx.tokenize("a: {:abc,=NONE}")
               |> SayCheezEx.expand()
    end

    test "Replace Elixir modules" do
      assert "a B.C" = SayCheezEx.replace_elixir_modules("a Elixir.B.C")

      # none found
      assert "a b c" = SayCheezEx.replace_elixir_modules("a b c")

      # multiple times
      assert "a B.C De.Ef" = SayCheezEx.replace_elixir_modules("a Elixir.B.C Elixir.De.Ef")

      # This is not an ELixir module because it's not capitalized
      assert "a Elixir.b.C" = SayCheezEx.replace_elixir_modules("a Elixir.b.C")
    end
  end
end
