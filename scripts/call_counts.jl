addprocs(8; exeflags=`--depwarn=no`)
using ComputeFramework
ctx = Context()
push!(LOAD_PATH, "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/")
import C
using JSON
using DataStructures
using Lazy

eco_dir = "/Users/isaac/Documents/julia_repos/"
base_dir = "/Users/isaac/github/julia/Base/"


out = C.count_exprs(C.search_dirs(base_dir), C.Selector(Any[[C.field(:head),x->x == :call], [C.field(:args), x->length(x) >=1]]))
d = @>> out map(x->x.args[1]) counter x->x.map
let f = open("/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/call_counts_base2.json", "w")
  write(f, JSON.json(d))
end

out = C.count_exprs(C.search_dirs(eco_dir), C.Selector(Any[[C.field(:head),x->x == :call], [C.field(:args), x->length(x) >=1]]))
d = @>> out map(x->x.args[1]) counter x->x.map
let f = open("/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/call_counts_eco2.json", "w")
  write(f, JSON.json(d))
end
