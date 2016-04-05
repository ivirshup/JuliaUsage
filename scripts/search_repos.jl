# # Searches repos for some stuff
#
# include("repo_setup.jl")
# using DataFrames
# import DataOps
# import RepoMgmt
# @everywhere data_pth = joinpath(pth, "data/repos/")
#
# df = deserialize(joinpath(data_pth, "repos.jld"))
# DataOps.module_usage(repo_dir, "Example")
