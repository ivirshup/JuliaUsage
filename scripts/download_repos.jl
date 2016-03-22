# addprocs(4)
# using ComputeFramework
# ctx = Context()

pth = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/"
push!(LOAD_PATH, pth)
using DataFrames
using SearchRepos

data = let df=readtable(joinpath(pth, "data/julia_repos.csv"))
  df[:repos] = map(x->x[30:end], df[:_url_])
  Array{AbstractString}(df[:repos])
end

if length(ARGS) == 0
  cd("/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage")
  out_path = joinpath(pth,"/data/repos/")
elseif length(ARGS) == 1
  out_path = ARGS[1]
elseif length(ARGS) == 2
  # out_path = "./data/repos/"
  out_path = joinpath(pth,"data/", "repos/")
  (idx1, idx2) = (parse(ARGS[1]), parse(ARGS[2]))
  println((idx1,idx2))
  data = data[idx1:idx2]
end
# data = data[1:500]
# println(data)
#
# a = distribute(data)
# b = map(x->download_repo(x, out_path), a)
# c = compute(Context(), b)

for i in data
  download_repo(i, out_path)
  println(i)
end
