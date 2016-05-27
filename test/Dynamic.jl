using FactCheck
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "..", "src"))
using Dynamic

#####
# SETUP
# Making a module I'll be searching.
#####
module ToSearch
# One required module
  import Combinatorics
  # Types
  abstract AbstractFoo{A, B}
  type Foo1{A, B} <: AbstractFoo{A, B}
    a::A
    b::B
  end
  type Foo2{A, B} <: AbstractFoo{A, B}
    a::A
    b::B
  end
  # Two TypeConstructors
  typealias FooIntA{A<:Integer, B} AbstractFoo{A, B}
  typealias FooIntB{A, B<:Integer} AbstractFoo{A, B}
  # Union
  typealias Foos Union{Foo1, Foo2}

  # One function with two methods
  foo(x::Int) = 1
  foo(x::AbstractFoo) = 2

  # Submodule
  module SubModule
    type Bar
      x::Int
    end
    bar(x::Int) = 3
  end

end

#####
# TESTS
#####

facts("Search a module") do

  context("Functions") do
    @fact length(Dynamic.get_something(ToSearch, Function)) --> 2 # eval + foo
    @fact length(Dynamic.get_something(ToSearch, Function, true)) --> 4 # 2x eval + foo + bar
    # Getting methods
    ms = Dynamic.get_methods(ToSearch, true)
    filter!(m->m.name!=:eval, ms) # Removing evals
    @fact length(ms) --> 3
  end

  context("Types") do
    @fact length(Dynamic.get_something(ToSearch, Type)) --> 6
    @fact Dynamic.get_something(ToSearch, Union) --> [ToSearch.Foos]
    @fact Dynamic.get_something(ToSearch, TypeConstructor) --> anyof([ToSearch.FooIntA, ToSearch.FooIntB], [ToSearch.FooIntB, ToSearch.FooIntA])
  end
  # TODO fix up get_required, speed and actually working.
  context("Modules") do
    @fact Set(Dynamic.get_something(ToSearch, Module)) --> Set([ToSearch.SubModule, ToSearch])
    @fact Set(Dynamic.get_required(ToSearch)) --> Set([ToSearch.SubModule, Combinatorics])
    @fact Dynamic.get_required(ToSearch, true) --> Set([ToSearch.SubModule, Combinatorics, Dynamic.get_required(Combinatorics)...])
  end

end

# Tests for convenience functions
facts("Useful") do

  @fact Dynamic.fieldtypedict(ToSearch.SubModule.Bar) --> Dict(:x=>Int)

  @fact Dynamic.parent_pkg(ToSearch.SubModule) --> ToSearch

  @fact Dynamic.get_module(ToSearch.AbstractFoo) --> ToSearch
  # @test get_module(ToSearch.)
end
