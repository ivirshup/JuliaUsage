_pth = normpath(joinpath(splitdir(@__FILE__)[2], ".."))
_data_pth = joinpath(_pth, "test_modules")
push!(LOAD_PATH, _pth)
using FactCheck
using FileTrees
using LightGraphs

facts("include") do
  context("included files") do
    files = FileTrees.find_includes(joinpath(_data_pth, "O.jl"))
    @fact Set(["M.jl", "N.jl"]) --> Set(map(x->splitdir(x)[2], files))
  end

  context("`include()` tree") do
    # O.jl in test_modules contains inclusions to M and O .jl
    tree, files = include_tree([joinpath(_data_pth, "O.jl")])
    @fact Set(["O.jl", "M.jl", "N.jl"]) --> Set(map(x->splitdir(x)[2], files))
    @fact tree.fadjlist --> Array{Int64}[[2,3],[],[]] # TODO make this more general. Order shouldn't matter.
  end

  context("Module tree") do
  end
end
