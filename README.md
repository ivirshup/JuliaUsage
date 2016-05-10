Project for looking at how people use Julia.

# Features

* System for searching/ querying large ASTs (`C.jl`)
  * `Selector` allows for passing serious of conditions for inclusion
  * `ASTp.jl` contains many premade conditionals for identifying parts of code.
* Plotting of files/ module trees
* `DynAl` contains some tools for dynamic analysis. Largely for collection of data.
  * `DynAl.get_something(m, Function, true)` returns all functions defined in module `m`
* Plotting of type lattices using:
  * `scripts/small_server.jl`: julia 0.4 code for plotting
  * `scripts/type_graph.jl`: julia 0.5 code for getting data

# TODO - tasks I'm likely to forget

* [ ] Get dynamic evaluation working.
* [ ] Plot edges with arrows (plotly doesn't like this.)
* [ ] Figure out a more dynamic way to plot.
<!--
# Reasoning about types

## What I want to do
  * Figure out how Julia users (in particular those outside of Base) reason about types

## Relevant Links
  * https://github.com/JuliaLang/julia/issues/8027 -->
