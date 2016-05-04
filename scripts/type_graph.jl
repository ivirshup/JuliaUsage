# Plots a graph of the type lattice for a module

push!(LOAD_PATH, "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage")
import DynAl
using Combinatorics

pkg_name = ARGS[1]
pkg_symbol = symbol(pkg_name)
println(pkg_symbol)
println("Starting for $(pkg_name)")
# Check to see if the package is actually installed:
if pkg_name in map(repr, DynAl.get_modules(Base, true))
  println("Getting $(pkg_name) from Base.")
  pkg_ref = reduce((x,y)->eval(x,y), Main, map(symbol, split(pkg_name, ".")))
elseif Pkg.installed(pkg_name) === nothing
  println("Couldn't find $(pkg_name) locally.")
  Pkg.available(pkg_name) # Allow to throw error
  throw(LoadError(@__FILE__, 11, "$(pkg_name) is not installed, but is available. Install it yerself."))
else
  println("Importing $(pkg_name).")
  try
    require(pkg_symbol)
    println(1)
  catch x
    println("Caught Error!")
    if length(names(eval(pkg_symbol))) > 1
      warn(x)
      println("Importing $(pkg_name) caused an error, but it looks fine. Continuing...")
    else
      Base.print_with_color(:Bold, "Oh no!")
      throw(x)
    end
  end
  pkg_ref = eval(Main, pkg_symbol)
  println("imported")
end

# Modules this uses. This is below requiring the module to be analyzed since sometimes
println("importing LightGraphs")
try
  using LightGraphs
catch x
  using LightGraphs
end

function prune_tree(g)
  pruning_order = sortperm(map(length, g.fadjlist), rev=true)
  new_tree = DiGraph(length(g.vertices))
  for node in pruning_order
    all_children = g.fadjlist[node]
    new_children = setdiff(all_children, union(g.fadjlist[all_children]...))
    for child in new_children
      add_edge!(new_tree, node, child)
    end
  end
  return new_tree
end

"""Creates type lattice"""
function type_graph(types::AbstractArray)
  idxmapping = ObjectIdDict()
  for (idx, i) in enumerate(types)
    idxmapping[i] = idx
  end
  typeedges = filter(x->(x[1]!=x[2])&&(x[1]<:x[2]),  permutations(types, 2)) |> collect
  edges = map(x->map(_->idxmapping[_]::Int, x), typeedges)
  g = DiGraph(length(types))
  map(x->add_edge!(g, x[2], x[1]), edges)
  g = prune_tree(g)
  names = [repr(x) for x in types]
  return g, names
end

"""Return array containing all types in lattice for a module."""
function get_pkg_types(pkg_ref::Module)
  types = DynAl.get_something(pkg_ref, Union{DataType, TypeConstructor}, true)
  push!(types, Any)
  push!(types, Union{})
  return unique(types) # Doesn't distinguish between Core and Base Array types
end

plotting_dir = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/plotting/"
data_dir = joinpath(plotting_dir, "pkg_type_data")
# function make_tree(pkg::Module)
#   types = DynAl.get_something(pkg, Union{DataType, TypeConstructor}, true)
#   idxmapping = ObjectIdDict()
#   for (idx, i) in enumerate(types)
#     idxmapping[i] = idx
#   end
#   typeedges = filter(x->(x[1]!=x[2])&&(x[1]<:x[2]),  permutations(types, 2)) |> collect |> unique
#   edges = map(x->map(_->idxmapping[_]::Int, x), typeedges)
#   g = DiGraph(length(types))
#   map(x->add_edge!(g, x[2], x[1]), edges)
#   # names = [repr(x) for x in types]
#   return g, names
# end
# I'm getting boxing errors with the above function, so I've switched to just doing it in the local scope
# SPECIAL CASE: CORE + BASE
# base_types = DynAl.get_something(Base, Union{DataType, TypeConstructor}, true)
# core_types = DynAl.get_something(Core, Union{DataType, TypeConstructor}, true)
# pkg_name = "Base+Core"
# types = union(base_types, core_types, [Union{}, Any])


types = DynAl.get_something(pkg_ref, Union{DataType, TypeConstructor}, true)






# types = unique(types) # Doesn't distinguish between Core and Base AbstractArray types. TODO?
types = get_pkg_types(pkg_ref)
g, names = type_graph(types)
# Show off
println("Created graph for $(pkg_name):")
println(g)
println()

graph_pth = joinpath(data_dir, string(pkg_name, "_graph.lg"))
name_pth = joinpath(data_dir, string(pkg_name, "_names.txt"))

println("Writing to $(graph_pth) & $(name_pth).")

open(graph_pth, "w") do f
   save(f, g)
end
open(name_pth, "w") do f
  for i in names
    println(f, i)
  end
end
# Now in julia4
# adjm = full(adjacency_matrix(g))
# names = map(Markdown.htmlesc, convert(Array{ASCIIString, 1}, map(repr, types)))
# function plot_graph{T<:AbstractString}(g::DiGraph, n::AbstractArray{T})
#   adjm = full(adjacency_matrix(g))
#   loc_x, loc_y = layout_spring_adj(adjm)
#   draw_layout_adj(adjm, locx, locy,
#     filename="data/plotting/distributiongraphlayout.svg",
#     labels=map(Markdown.htmlesc, n),
#     labelsize=3.0)
# end
# layout_tree(g.fadjlist, names;
#   filename="data/plotting/distributiontypetree.svg",
#   cycles=false,
#   ordering=:barycentric)
