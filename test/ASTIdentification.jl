push!(LOAD_PATH, joinpath(dirname(@__FILE__), ".."))
using FactCheck
using C
import ASTp

facts("Functions") do
  context("do") do
    # `do` syntax defines anonymous functions on the parser level.
    wo_args = parse("""
    remotecall_fetch(2) do
      println("hi")
    end
    """)
    w_args = parse("""
    map([1,2,3]) do x
      println(x)
    end
    """)
    @fact length(parse_ast(w_args, Selector([ASTp.isfunction]))) --> 1
    @fact length(parse_ast(wo_args, Selector([ASTp.isfunction]))) --> 1
    @fact length(parse_ast(w_args, Selector([ASTp.isanon]))) --> 1
    @fact length(parse_ast(wo_args, Selector([ASTp.isanon]))) --> 1
  end

  context("->") do
    map_ex = parse("""map(x->x, [1,2,3])""")
    @fact ASTp.isfunction(map_ex) --> false
    not_lnn = x->!isa(x, LineNumberNode)
    @fact filter_ast!(not_lnn, parse_ast(map_ex, Selector([ASTp.isfunction]))) --> filter_ast!(not_lnn, [:(x->x)])
    @fact filter_ast!(not_lnn, parse_ast(map_ex, Selector([ASTp.isanon]))) --> filter_ast!(not_lnn, [:(x->x)])
  end

  context("function declarations") do
    decl = parse("""
    function foo(x)
      return y -> x+1
    end
    """)
    decl_nested = parse("""
    function foo(x)
      function bar(x)
        y -> y / x
      end
      bar(x)
    end
    """)
    @fact ASTp.isfunctiondecl(decl) --> true
    @fact ASTp.isfunctiondecl(decl_nested) --> true
    @fact length(parse_ast(decl, Selector([ASTp.isfunctiondecl]))) --> 1
    @fact length(parse_ast(decl_nested, Selector([ASTp.isfunctiondecl]))) --> 2
  end
end

facts("Types") do
  context("Type Declarations") do
    abst = :(abstract AbstractFoo)
    cncrt = :(type Foo x::Bar end)
    inhrt = :(type Foo <: AbstractFoo x::Bar end)
    sngl = :(type Singleton end)
    immut_sngl = :(immutable Singleton end)
    als = :(typealias Foo <: Bar)
    map([abst, cncrt, inhrt, sngl, immut_sngl]) do x @fact ASTp.istypedecl(x) --> true "error with $x" end
    # @fact all(ASTp.istypedecl, [abst, cncrt, inhrt, sngl, immut_sngl] --> true
    @fact all(ASTp.isconcretedecl, [cncrt, inhrt, sngl, immut_sngl]) --> true
    @fact ASTp.isconcretedecl(abst) --> false
    @fact ASTp.isabstractdecl(abst) --> true
    @fact ASTp.isinheritance(inhrt) --> true # TODO
    @fact ASTp.isimmutabledecl(immut_sngl) --> true
    @fact ASTp.istypealias(als) --> true
  end
end
