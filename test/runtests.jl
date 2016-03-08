addprocs(1) # For parallel checks
push!(LOAD_PATH, "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/")
using FactCheck
import C

TEST_DATA_DIR = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/test_modules/"
TEST_DATA_FILES = files = [string(TEST_DATA_DIR, "M.jl"),
                           string(TEST_DATA_DIR, "N.jl"),
                           string(TEST_DATA_DIR, "O.jl")]

facts("Queries") do
  # Simple test to see if I'm up most things
  context("Curlies") do
    s = C.Selector([x->x.head == :curly])
    out = C.count_exprs(TEST_DATA_FILES, s)
    @fact length(out) --> 4
    @fact :(Union{Int,Float}) in out --> true # Is there no `has`?
  end

  context("Function") do

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
