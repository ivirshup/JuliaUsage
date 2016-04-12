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
    @fact ASTp.functionsig(decl) --> [:x]
    @fact parse_ast(decl_nested, Selector([x->isa(x, Expr), ASTp.iscalling(:bar)])) --> [:(bar(x)),:(bar(x))]
    @fact parse_ast(decl_nested, Selector([x->isa(x, Expr), ASTp.iscalling([:/, :bar])])) --> [:(bar(x)),:(y/x),:(bar(x))]
    # @fact ASTp.iscalling(decl_nested, :bar) --> true
    # @fact ASTp.iscalling(decl_nested, [:/, :bar]) --> true
    @fact ASTp.getcalls(decl_nested) --> [:/, :bar]
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

  context("Signatures") do
    typed = :(bar(x::Foo, y::AbstractFoo) = convert(promote_type(typeof(x), typeof(y)), y))
    kwded = parse("function bar(x::Int,g::Int=1)\n (g+x)::Int end")
    rlkwded = :(bar(x;y::Int=1) = println(x,y))
    @fact parse_ast(typed, Selector([ASTp.isannotation])) --> [:(x::Foo), :(y::AbstractFoo)]
    @fact parse_ast(kwded, Selector([ASTp.isannotation])) --> [:(x::Int), :(g::Int), :((g+x)::Int)]
    # @fact parse_ast(kwded, Selector([ASTp.iskwds])) --> [:($(Expr(:parameters, (Expr(:kw, :g, 1)))))] # These are kinda a pain to write. # Did I ever have a method for this?
    @fact parse_ast(kwded, Selector(Any[ASTp.isfunction, [ASTp.functionsig, x->any(ASTp.isannotation, x)]])) --> [kwded]
    @fact ASTp.functionsig(typed) --> [:(x::Foo), :(y::AbstractFoo)]
    @fact ASTp.functionsig(kwded) --> [:(x::Int), Expr(:kw, Expr(:(::), :g, :Int), 1)]
    # @fact parse_ast(typed, Selector([ASTp.issig])) -->
  end
end
