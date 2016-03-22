
addprocs(8; exeflags=`--depwarn=no`)
using ComputeFramework
ctx = Context()
push!(LOAD_PATH, "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/")
import C
using JSON
using DataStructures
using Lazy

test_dir = "test_modules/"
eco_dir = "/Users/isaac/Documents/julia_repos/"
base_dir = "/Users/isaac/github/julia/Base/"

out_base = C.count_exprs(C.search_dirs(base_dir), C.Selector(Any[[C.field(:args), x->:Array in x]]))
out_eco = C.count_exprs(C.search_dirs(eco_dir), C.Selector(Any[[C.field(:args), x->:Array in x]]))



d = Dict()
d["eco"] = (@>> out_eco counter x->x.map)
d["base"] = (@>> out_base map(x->x.args[1]) counter x->x.map)
for i in ["eco", "base"]
  f = open("/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/array_inits_$(i).json", "w")
  write(f, JSON.json(d[i]))
  close(f)
end
