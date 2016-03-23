addprocs(1) # For parallel checks
push!(LOAD_PATH, "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/")
using FactCheck
import C

TEST_DATA_DIR = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/test_modules/"
TEST_DATA_FILES = files = [string(TEST_DATA_DIR, "M.jl"),
                           string(TEST_DATA_DIR, "N.jl"),
                           string(TEST_DATA_DIR, "O.jl")]
"""A type for testing"""
type TestType
 x::Int
end

facts("Queries") do
  # Simple test to see if I'm up most things
  context("Curlies") do
    s = C.Selector([x->x.head == :curly])
    out = C.count_exprs(TEST_DATA_FILES, s) # Throws a lot of warnings, but tells me if results will be similar
    @fact length(out) --> 4
    @fact :(Union{Int,Float}) in out --> true # Is there no `has`?
    # New syntax
    s = C.Selector(Any[[C.field(:head), x -> x == :curly]])
    out2 = C.count_exprs(TEST_DATA_FILES, s)
    @fact out2 --> out # Should I make sure they don't test for order? #
  end

  context("Selectors") do
    test_access = :(x.y)
    # Equality tests here may be bad examples, since they'll work for field(:y)(x) == z, but the case I'm worried about is field(:y)(x) > z
    @fact C.Selector([x -> x.head == :.])(test_access) --> true
    @fact C.Selector(Any[[C.field(:head), x -> x == :.]])(test_access) --> true #
    @fact C.Selector(Any[[C.field([:args, 2, :value]), x -> x == :y]])(test_access) --> true #

    # Mixed access
    test_curly = :(Union{Array,Int})
    @fact C.Selector(Any[[C.field(:head), x -> x == :curly], x->length(x.args)==3])(test_curly)--> true #
    @fact C.Selector(Any[[C.field(:head), x -> x != :curly], x->length(x.args)==3])(test_curly)--> false #
    @fact C.Selector(Any[[C.field(:head), x -> x == :curly], x->length(x.args)>3])(test_curly)--> false
    @fact C.Selector(Any[[C.field(:head), x -> x > :curly], x->length(x.args)==3])(test_curly)--> false #

    @fact C.Selector([C.field(:tail)])(test_curly) --> false
  end
  # context("Curlies syntax2") do
  #   s = C.Selector([(field(:head), x->x == :curly)])
  #   out = C.count_exprs(TEST_DATA_FILES, s)
  #   @fact length(out) --> 4
  #   @fact :(Union{Int,Float}) in out --> true
  #
  #
  # end

  context("Field access") do
    foo = TestType(1)
    @fact C.field(foo, :x) --> 1
    @fact C.field(foo, :y) --> C.EmptyField()
    # Alt syntax
    @fact C.field(:x)(foo) --> C.field(foo, :x)
    @fact C.field(:y)(foo) --> C.field(foo, :y)
    # Arrays/ nested
    @fact C.field(:(x.y), [:args, 2, :value]) --> :y
    @fact C.field([:args, 2, :value])(:(x.y)) --> :y
    # hasfield
    @fact C.hasfield(TestType, :x) --> true
    @fact C.hasfield(TestType, :y) --> false
    # @fact C.hasfield(TestType, 1)
  end

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
  #   find_0dim = C.Selector(Any[x->isa(x,Expr), x->x.head==:curly , x->x.args[1] == :Array, x->isdefined(x.args, 3) ? x.args[3] == 0 : true])
  #   out = C.parse_ast(C.parse_file(f), find_0dim)
  #   @fact length(out) --> 3
  # end

end

facts("Type info") do
  type_file = joinpath(TEST_DATA_DIR, "Types.jl")
  type_ast = C.parse_file(type_file)

  context("Type declarations") do
    any_q = C.Selector(Any[[C.field(:head), x->(x == :type || x== :abstract)]])
    singleton_q = C.Selector(Any[[C.field(:head), x->x==:type],
                               [C.field([:args,3,:args]), x->length(x) == 0]])
    abst_q = C.Selector(Any[x->C.field(x, :head) == :abstract])
    @fact length(C.parse_ast(type_ast, any_q)) --> 5
    singletons = C.parse_ast(type_ast, singleton_q)
    @fact length(singletons) --> 2
    @fact :(immutable iSingleton end) in singletons --> true
    @fact :(type Singleton end) in singletons --> true
    absts = C.parse_ast(type_ast, abst_q)
    @fact :(abstract AbstractFoo) in absts --> true
  end

  context("disptach? check? this thing -> ::") do
    q = C.Selector(Any[x->C.field(x, :head) == :(::)])
    res = C.parse_ast(type_ast, q)
    @fact length(res) --> 5
    @fact :(x::Type) in res --> true
  end

  context("Type algebra") do
    funcs = ["typeof", "isa", "eltype"]
  end

end

facts("Files + parsing") do

  context("File reading") do # For finding and parsing files
  # Test that the parser can read a file
  # Figure out what's throwing errors, maybe see if I can read the others.
    # Make tests for those?
    for file in TEST_DATA_FILES
      parsed = C.parse_file(file)
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

    @fact C.parse_file(make_bad_file()) --> Array{Any,1}(0)
    @fact_throws ParseError parse(make_bad_file())

    # Making sure file still throws error in parallel
    @fact C.count_exprs([make_bad_file()], C.Selector([x->true])) --> Array{Any,1}(0)
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
