addprocs(4)

using ComputeFramework
ctx = Context()

push!(LOAD_PATH, "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/")
using SearchRepos
using DataFrames
using DataStructures


julia_repos = let df=readtable("data/julia_repos.csv")
    df[:repos] = map(x->x[30:end], df[:_url_])
    Array{AbstractString}(df[:repos])
end
unique_users = unique(map(x->split(x, "/")[1], julia_repos))

@everywhere function find_dependents(p_name, deps = DataStructures.OrderedDict())
    deps[p_name] = Dict()
    dependents = Pkg.dependents(p_name)
    deps[p_name]["dependents"] = dependents
    new = setdiff(Pkg.dependents(p_name), deps.keys )
    for i in new
        find_dependents(i, deps)
    end
    deps
end
@everywhere out = find_dependents("ForwardDiff")

@everywhere test_terms = map(AbstractString, collect(keys(out)))

# test

a = distribute(julia_repos[2:5])
b = map(x->SearchRepos.search_repo(x, test_terms; dir_path="data/test"), a)
c = gather(Context(), b)

println(c)
