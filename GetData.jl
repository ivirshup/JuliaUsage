
"""Provides functions for loading data"""
module GetData
using DataStructures
export repos, find_dependents

DIR = dirname(@__FILE__)
repo_pth = joinpath(DIR, "data", "repos")
repos() = filter(x->contains(x, ".zip"), readdir(repo_pth))

"""Returns registered packages which are dependents of passed package name, then recurses on them"""
function find_dependents(p_name, deps = OrderedDict())
    deps[p_name] = Dict()
    dependents = Pkg.dependents(p_name)
    deps[p_name]["dependents"] = dependents
    new = setdiff(Pkg.dependents(p_name), deps.keys )
    for i in new
        find_dependents(i, deps)
    end
    deps
end


repo_names = let f = open(joinpath(DIR, "data", "julia_repos.jld"), "r")
  data = deserialize(f)
  close(f)
  return data
end


end
