# Changelog


## 0.3.0 - 2023-08-12

* Added initial support for Graphviz and PlantUML

## 0.2.3 - 2023.04.14

* Fixes #20 - Remove Elixir prefix from module names
* Fixes #18 - C Compiler attribute would not work on Windows. Thanks @milangupta1 


## 0.2.2 - 2023.04.11

* Fixes #16 - _major bug_: cheez!() returned source string instead of expanded
* Fixes #15 - Capture mix.env
* Fixes #13 - Compiled architecture and BEAM attributes


## 0.2.1 - 2023.03.20

- Separated functions `cheez!` and `cheez`, where the first one
  prints out on standard out the captured string (as to earmark the compile log)
- Improved documentation 

## 0.2.0 - 2023.03.19

- NEW! Compact string format (fixes #14)
- Reading hostname (fixes #12) 

## 0.1.5 - 2023.03.09

- Able to read the date from ancient versions of Git. (bug #7)

## 0.1.4 - 2023.02.15

- Fixed typos in documentation
- Added msg method
- Will now print missing variables on stdout
- Fixes #10 - Camelized project name
- Fixes #8 - Git: unknown date format

## 0.1.3 - 2023.02.14

- Improved documentation
- Added Credo and Dialyzer

## 0.1.1

- First useful results.

