# Plots a graph of the type lattice for a module

# Usage:
# import P
# import Module
# types = P.get_pkg_types(Module)
# g, t_names = P.type_graph(types)
# colors = P.make_colors(map(P.diff_type, types))
# t_names = P.name_w_method_counts(types) # Gives more info for names
# P.plot_with_color(title, g, t_names, colors)
module P
push!(LOAD_PATH, "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage")
import DynAl
using Combinatorics
using Colors
import JSON
#
# pkg_name = ARGS[1]
# pkg_symbol = symbol(pkg_name)
# println(pkg_symbol)
# println("Starting for $(pkg_name)")
# # Check to see if the package is actually installed:
# if pkg_name in map(repr, DynAl.get_modules(Base, true))
#   println("Getting $(pkg_name) from Base.")
#   pkg_ref = reduce((x,y)->eval(x,y), Main, map(symbol, split(pkg_name, ".")))
# elseif Pkg.installed(pkg_name) === nothing
#   println("Couldn't find $(pkg_name) locally.")
#   Pkg.available(pkg_name) # Allow to throw error
#   throw(LoadError(@__FILE__, 11, "$(pkg_name) is not installed, but is available. Install it yerself."))
# else
#   println("Importing $(pkg_name).")
#   try
#     require(pkg_symbol)
#     println(1)
#   catch x
#     println("Caught Error!")
#     if length(names(eval(pkg_symbol))) > 1
#       warn(x)
#       println("Importing $(pkg_name) caused an error, but it looks fine. Continuing...")
#     else
#       Base.print_with_color(:Bold, "Oh no!")
#       throw(x)
#     end
#   end
#   pkg_ref = eval(Main, pkg_symbol)
#   println("imported")
# end
const plotting_dir = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/plotting/"
const data_dir = joinpath(plotting_dir, "pkg_type_data")




# Modules this uses. This is below requiring the module to be analyzed since sometimes
println("importing LightGraphs")
try
  using LightGraphs
catch x
  using LightGraphs
end

"""
Given a type graph, removes all redundant edges (e.g. a path between nodes
already exists.)
"""
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

"""
Creates type lattice

Args:
    types: Array of types to make a graph out of

Returns:
    * DiGraph showing subtype relationships
    * List of names ordered along with the nodes
"""
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

"""Create array of names using the number of methods which dispatch on a type"""
function name_w_method_counts(types::AbstractArray)
  a = map(methodswith, types)
  n = length(types)
  return map(x->string(x...), zip(map(repr, types), fill("\t", n), map(length, a)))
end

"""Return array containing all types in lattice for a module."""
function get_pkg_types(pkg_ref::Module, oftype=Union{DataType,TypeConstructor})
  types = DynAl.get_something(pkg_ref, oftype, true)
  types = convert(Array{Type,1}, types)
  push!(types, Any)
  push!(types, Union{})
  return unique(types) # Doesn't distinguish between Core and Base Array types
end

function module_dispatch_lattice_counts(m::Module)
  ms = DynAl.module_methods(m, true)
  types = collect(Base.flatten(map(DynAl.method_sig_types, ms)))
  type_counts = copy(types)
  types = DynAl.unique_types(types)
  push!(types, Union{})
  d = Dict{eltype(types), Int}()
  for t in types
    n = length(filter(x->DynAl.are_same_type(t, x), type_counts))
    d[t] = n
  end
  return types, d
end

function dispatch_count_names(types, d)
  map(x->"$(x) $(d[x])", types)
end

"""
Returns lattice of method signatures.

If called with `for_plotting=true`(optional `Bool` argument) will insert `Union{}`
into the lattice, resulting in nicer looking plots.
"""
function method_sig_lattice(ms::Vector, for_plotting::Bool=false)
  method_sigs = map(x->x.sig, ms)
  if for_plotting push!(method_sigs, Union{}) end # Makes the formatting way nicer
  g, t_names = type_graph(method_sigs)
  return g, t_names
end
method_sig_lattice(ms::Function, for_plotting::Bool=false) = method_sig_lattice(collect(methods(ms)), for_plotting)

"""
Convenience function for returning all types in dispatch lattice from a module
"""
function module_dispatch_lattice(m::Module)
  ms = DynAl.module_methods(m, true)
  types = collect(Base.flatten(map(DynAl.method_sig_types, ms)))
  types = DynAl.unique_types(types)
  push!(types, Union{})
  return types
end

"""
Given an array of categorical elements, returns an array of colors mapped to the elements.
"""
function make_colors(catlist::AbstractArray)
    elements = unique(catlist)
    sort!(elements, by=hash) # Should make colors stay the same between graph types
    n = length(elements)
    colors_set = map(hex, Colors.distinguishable_colors(n))
    mapping = Dict(map(x->Pair(x...), zip(elements, colors_set)))
    return map(x->mapping[x], catlist)
end

"""
Function which differentiates types based on what it does.
"""
function diff_type(x)
    t = typeof(x)
    if isa(x, DataType)
        if x.abstract
            "abstract"
        else
            t
        end
    else
        t
    end
end

"""Failure safe isleaftype"""
function is_leaf(x)
  try
    isleaftype(x)
  catch
    false
  end
end

function node_type(x)
  if isa(x, DataType)
    if x.abstract
      "abstract"
    elseif isleaftype(x)
      "leaftype"
    else
      "other_concrete"
    end
  else
    typeof(x)
  end
end

function color_json(path::String, differentiable::AbstractArray, difference_maker::Function=diff_type)
    clrs = make_colors(map(difference_maker, differentiable))
    d = Dict("color"=>clrs)
    open(joinpath(data_dir, path), "w") do f
        write(f, JSON.json(d))
    end
    d
end

using Requests

plot_graph(pkg::AbstractString) = readall(get("http://0.0.0.0:8000/plot/$pkg"))
plot_with_color(pkg::AbstractString) = readall(get("http://0.0.0.0:8000/plot_with_color/$pkg"))


function plot_graph(pkg_name::AbstractString, g::DiGraph, names)
  graph_pth = joinpath(data_dir, string(pkg_name, "_graph.lg"))
  name_pth = joinpath(data_dir, string(pkg_name, "_names.txt"))
  open(graph_pth, "w") do f
     LightGraphs.save(f, g)
  end
  open(name_pth, "w") do f
    for i in names
      println(f, i)
    end
  end
  plot_graph(pkg_name)
end

function plot_with_color(pkg_name::AbstractString, g::DiGraph, names, colors::AbstractArray)
  graph_pth = joinpath(data_dir, string(pkg_name, "_graph.lg"))
  name_pth = joinpath(data_dir, string(pkg_name, "_names.txt"))
  color_pth = joinpath(data_dir, string(pkg_name, "_colors.json"))
  open(graph_pth, "w") do f
     LightGraphs.save(f, g)
  end
  open(name_pth, "w") do f
    for i in names
      println(f, i)
    end
  end
  open(color_pth, "w") do f
    d = Dict("color"=>colors)
    open(joinpath(data_dir, color_pth), "w") do f
        write(f, JSON.json(d))
    end
  end
  println("plot!")
  plot_with_color(pkg_name)
end


function plot_color(pkg::Module)
  name = string(repr(pkg), "_nodetypes")
  types = get_pkg_types(pkg, Type)
  g, t_names = type_graph(types)
  t_names = name_w_method_counts(types)
  colors = make_colors(map(node_type, types))
  plot_with_color(name, g, t_names, colors)
end
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


# types = DynAl.get_something(pkg_ref, Union{DataType, TypeConstructor}, true)



# types = unique(types) # Doesn't distinguish between Core and Base AbstractArray types. TODO?
# types = get_pkg_types(pkg_ref)
# g, names = type_graph(types)
# # Show off
# println("Created graph for $(pkg_name):")
# println(g)
# println()
#
# graph_pth = joinpath(data_dir, string(pkg_name, "_graph.lg"))
# name_pth = joinpath(data_dir, string(pkg_name, "_names.txt"))
# color_pth = joinpath(data_dir, )
#
# println("Writing to $(graph_pth) & $(name_pth).")
#
# open(graph_pth, "w") do f
#    save(f, g)
# end
# open(name_pth, "w") do f
#   for i in names
#     println(f, i)
#   end
# end
# P.color_json(string(pkg_name, "_names.txt"), types)
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
end
