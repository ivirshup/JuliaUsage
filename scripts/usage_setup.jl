_pth = joinpath(splitdir(@__FILE__)[1], "..")
(_pth in LOAD_PATH) ? nothing : push!(LOAD_PATH, _pth)

using DataFrames
using Plots
using C
using ASTp
using DataStructures

t_counts = deserialize(open(joinpath(_pth,"data/tycounts.jld")))
df = readtable(joinpath(_pth, "data/typerdf.dat"))


test_dir = "test_modules/"
eco_dir = "/Users/isaac/Documents/julia_repos/"
base_dir = "/Users/isaac/github/julia/Base/"
test_files = C.search_dirs(test_dir)
eco_files = C.search_dirs(eco_dir)
base_files = C.search_dirs(base_dir);
