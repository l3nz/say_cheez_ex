# SayCheezEx 📸  

Captures a snapshot of the environment at build time, so you can display it at run-time.

Sometimes you'd want to reference the version of your package at run time, or when / where / from what sources it was built, but that information is not available anymore once you deploy your app somewhere else.

This library is heavily ispired by my previous Clojure library https://github.com/l3nz/say-cheez that has been proven useful over the years.


[![Hex.pm](https://img.shields.io/hexpm/v/say_cheez_ex)](https://hex.pm/packages/say_cheez_ex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/say_cheez_ex)
[![Hex.pm](https://img.shields.io/hexpm/dt/say_cheez_ex)](https://hex.pm/packages/say_cheez_ex)
[![Hex.pm](https://img.shields.io/hexpm/l/say_cheez_ex)](https://github.com/l3nz/say_cheez_ex/blob/main/LICENSE)



## Using

Whenever you want to reference a version/build information,
create an Elixir attribute for the module and compute its value through SayCheezEx.

I often compute a "short" version number,
an User-Agent for performing HTTP requests,
and a full version that contains the full
build information.

For example:

```
module Foo.Bar do
        import SayCheezEx, only: [cheez!: 1]

        # Create all attributes we need

        # "v 0.1.5/d9a87c3 137 on server.local"
        @version cheez!(
                "v {:project_version}/{:git_commit_id} {:build_number} on {:build_on}"
        )
      
        # "0.1.5 d9a87c3/230411.1227 B:137/230411.1434/prod Ex:1.14.3/OTP25"
        @version_full cheez!(
                "{:project_version} {:git_all} B:{:build_number,=-}/{:build_at}/{:build_mix_env} Ex:{:system}"
        )


        # "Foo.Bar MyProject-0.1.1" 
        @user_agent cheez!("#{__MODULE__} {:project_name}-{:project_version}")

        ...
end
```

Always make sure that you assign those values to an attibute - **never call those functions directly**.

You can safely create such attributes in all modules that need them, as they are just one (usually very small) binary.

Strings composed through `cheez!` will interpolate attributes
between brackets, with the following rules:

- `{:project_version}` is an info tag. These is a long 
   list of those - see below.
- `{$HOST}` is the environment variable HOST
- `{=HELLO}` is a default value, in this case the literal string "HELLO"
- If multiple attributes are specified, they all are expanded,
  and the first one that is defined will be output. So e.g.
  `{$FOO,$BAR,=BAZ}` will first try to interpolate the variable FOO;
  if that is undefined, it will try BAR, and if that too is undefined,
  it will output "BAZ" (that is always defined)


### What is available

- The name of this project, its version, the version of Elixir and OTP
- When the project was built, where was it built and by which user, the build number (if available)
- The current Git SHA that was built, when the last commit was made and by whom.
- A set of properties about the current BEAM VM (architecture, word size, etc.)
- The host name that this project was built on
- The mix environment that this project was built in (e.g. "prod" or "dev" or "test")

See https://hexdocs.pm/say_cheez_ex/SayCheezEx.html#info/1 for a full list.

You can also call `SayCheezEx.all()` for a
map with all available attributes:


````
%{
  build_at: "230411.1538",
  build_at_day: "2023-04-11",
  build_at_full: "2023-04-11.15:38:40",
  build_by: "lenz",
  build_number: "87",
  build_on: "MacBook-Pro.local",
  build_mix_env: "dev",
  git_all: "b204919/230411.1509",
  git_commit_id: "b204919",
  git_commit_id_full: "b2049190312ef810875476398978c2b0387251d3",
  git_date: "2023-04-11.15:09:50",
  git_date_compact: "230411.1509",
  git_last_committer: "Lenz",
  project_full_version: "0.2.1/b204919/230411.1509",
  project_name: "SayCheezEx",
  project_version: "0.2.1",
  sysinfo_arch: "aarch64-apple-darwin22.3.0",
  sysinfo_banner: "Erlang/OTP 25 [erts-13.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]",
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
  ....
}
````


## Installing

Just add to your `mix.exs` file:

        {:say_cheez_ex, "~> 0.2"}


- Full documentation: https://hexdocs.pm/say_cheez_ex
- Hex.pm: https://hex.pm/packages/say_cheez_ex




# Roadmap

- Display runtime information (memory, cpu) in a compact and handy way



