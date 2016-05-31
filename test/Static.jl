addprocs(1) # For parallel checks
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "..", "src"))
using FactCheck
import Static
using ASTp

# TODO clean this out
TEST_DATA_DIR = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/test_modules/"
TEST_DATA_FILES = files = [string(TEST_DATA_DIR, "M.jl"),
                           string(TEST_DATA_DIR, "N.jl"),
                           string(TEST_DATA_DIR, "O.jl")]
"""A type for testing"""
type TestType
 x::Int
end

# facts("grepping") do
#   context()
# end

facts("Queries") do
  # Simple test to see if I'm up most things
  context("Curlies") do
    s = Static.Selector(Any[[Static.field(:head), x->x==:curly]])
    out = Static.count_exprs(TEST_DATA_FILES, s) # Throws a lot of warnings, but tells me if results will be similar
    @fact length(vcat(out...)) --> 4
    @fact :(Union{Int,Float}) in union(reduce(vcat, out)) --> true # Is there no `has`?
    # New syntax
    s = Static.Selector(Any[[Static.field(:head), x -> x == :curly]])
    out2 = Static.count_exprs(TEST_DATA_FILES, s)
    @fact out2 --> out # Should I make sure they don't test for order? #
  end

  context("Selectors") do
    test_access = :(x.y)
    # Equality tests here may be bad examples, since they'll work for field(:y)(x) == z, but the case I'm worried about is field(:y)(x) > z
    @fact Static.Selector([x -> x.head == :.])(test_access) --> true
    @fact Static.Selector(Any[[Static.field(:head), x -> x == :.]])(test_access) --> true #
    @fact Static.Selector(Any[[Static.field([:args, 2, :value]), x -> x == :y]])(test_access) --> true #

    # Mixed access
    test_curly = :(Union{Array,Int})
    @fact Static.Selector(Any[[Static.field(:head), x -> x == :curly], x->length(x.args)==3])(test_curly)--> true #
    @fact Static.Selector(Any[[Static.field(:head), x -> x != :curly], x->length(x.args)==3])(test_curly)--> false #
    @fact Static.Selector(Any[[Static.field(:head), x -> x == :curly], x->length(x.args)>3])(test_curly)--> false
    @fact Static.Selector(Any[[Static.field(:head), x -> x > :curly], x->length(x.args)==3])(test_curly)--> false #

    @fact Static.Selector([Static.field(:tail)])(test_curly) --> false
  end
  # context("Curlies syntax2") do
  #   s = Static.Selector([(field(:head), x->x == :curly)])
  #   out = Static.count_exprs(TEST_DATA_FILES, s)
  #   @fact length(out) --> 4
  #   @fact :(Union{Int,Float}) in out --> true
  #
  #
  # end
  context("Functions") do
    @fact Static.parse_ast(:(sum(1,2)), x->Static.field(x, :head)==:call) --> Any[:(sum(1,2))]
  end

  context("Field access") do
    foo = TestType(1)
    @fact Static.field(foo, :x) --> 1
    @fact Static.field(foo, :y) --> Static.EmptyField()
    # Alt syntax
    @fact Static.field(:x)(foo) --> Static.field(foo, :x)
    @fact Static.field(:y)(foo) --> Static.field(foo, :y)
    # Arrays/ nested
    @fact Static.field(:(x.y), [:args, 2, :value]) --> :y
    @fact Static.field([:args, 2, :value])(:(x.y)) --> :y
    # hasfield
    @fact Static.hasfield(TestType, :x) --> true
    @fact Static.hasfield(TestType, :y) --> false
    # @fact Static.hasfield(TestType, 1)
  end

  # Parsing expressions and removing unwanted data. Like line number nodes which mess with equality.
  context("Filter expressions") do
    filt = y->Static.filter_ast(x->Static.field(:head)(x)!=:line, y)
    @fact parse("\nx->x") != parse("x->x") --> true
    @fact filt(parse("\nx->x")) --> filt(parse("x->x"))
  end

  context("Map Expressions") do
    @fact Static.map_ast!(x->x.args[1] = :-, Static.Selector([isexpr, x->iscalling(x, :+)]), :((x+y)*2)) --> :((x-y)*2)
  end
  # context("In ast") do
  #   ex = :(y + x)
  # end
  # context("Zero dim arrays") do # Not working
  #   file = """
  #   module Test
  #   x = Array{Int}()
  #   y = Array{Int}(2) # Has dimensions
  #   y = Array{Int, 0}(3) # Wont init
  #   x * Array{String,0}("hello") # Won't init
  #   Array{Int}(1,2,3) # Has dims
  #   Array(Int)(1) # Won't init_pipe
  #   x = Array(Int)
  #   x[1] = 2 # Sets value in a zero-dim array
  #   Base.cell_1d() # Returns a zero dim array
  #   end
  #   """
  #   (f, io) = mktemp()
  #   write(io, file)
  #   close(io)
  #   find_0dim = Static.Selector(Any[x->isa(x,Expr), x->x.head==:curly , x->x.args[1] == :Array, x->isdefined(x.args, 3) ? x.args[3] == 0 : true])
  #   out = Static.parse_ast(Static.parse_file(f), find_0dim)
  #   @fact length(out) --> 3
  # end

end

# TODO confirm if what's broken about these tests
facts("Type info") do
  remlines(y) = Static.filter_ast(x->Static.field(:head)(x)!=:line, y)
  type_file = joinpath(TEST_DATA_DIR, "Types.jl")
  type_ast = remlines(Static.parse_file(type_file))

  context("Type declarations") do
    any_q = Static.Selector(Any[[Static.field(:head), x->(x == :type || x== :abstract)]])
    singleton_q = Static.Selector(Any[[Static.field(:head), x->x==:type],
                               [Static.field([:args,3,:args]), x->length(x) == 0]])
    abst_q = Static.Selector(Any[x->Static.field(x, :head) == :abstract])
    @fact length(Static.parse_ast(type_ast, any_q)) --> 5
    singletons = Static.parse_ast(type_ast, singleton_q)
    @fact length(singletons) --> 2
    @fact remlines(:(immutable iSingleton end)) in singletons --> true
    @fact remlines(:(type Singleton end)) in singletons --> true
    absts = Static.parse_ast(type_ast, abst_q)
    @fact :(abstract AbstractFoo) in absts --> true
  end

  context("disptach? check? this thing -> ::") do
    q = Static.Selector(Any[x->Static.field(x, :head) == :(::)])
    res = Static.parse_ast(type_ast, q)
    @fact length(res) --> 5
    @fact :(x::Type) in res --> true
  end

  context("Type algebra") do
    funcs = [:typeof, :isa, :eltype, :convert]
  end

end

facts("Files + parsing") do

  context("File reading") do # For finding and parsing files
  # Test that the parser can read a file
  # Figure out what's throwing errors, maybe see if I can read the others.
    # Make tests for those?
    for file in TEST_DATA_FILES
      parsed = Static.parse_file(file)
      @fact isa(parsed, Array) --> true
      #@fact unique(typeof, parsed) --> Expr
    end
  end

  context("Weird-bad-file") do
    """Returns weird file found in 'BlackBoxOptim/examples/benchmarking/updatetoplist.jl'"""
    function make_bad_file()
      contents = """julia --color=yes -L ../../src/BlackBoxOptim.jl compare_optimizers.jl list --benchmarkfile benchmark_runs_150712.csv -o latest_toplist.csv"""
      (f,io) = mktemp()
      write(io, contents)
      close(io)
      f
    end

    @fact Static.parse_file(make_bad_file()) --> Array{Any,1}(0)
    @fact_throws ParseError parse(make_bad_file())

    # Making sure file still throws error in parallel TODO does this check that?
    @fact Static.count_exprs([make_bad_file()], Static.Selector([x->true])) --> Any[Any[]]
  end

end
rmprocs(workers())
# facts("Git")
#
#   context("Blame") do  # Ability to credit code
#   # Maybe just blame a file in this repo?
#   @fact true --> false
#   end
#
#   context("update") do # map across repos + parallel
#   # Pull for a repo, skip if there's a complication
#   @fact true --> false
#   end
#
# end
