# Creates trees from julia source files.
# push!(LOAD_PATH, @__FILE__)
module FileTrees

using LightGraphs
using C
using ASTp

export include_tree

"""Given a list of files, returns a directed graph of inclusion."""
function include_tree(files::Array)
  # Check to see if we have any new files
  edges = map(find_includes, files)
  nodes = union(files, reduce(vcat, edges)) # Maintains order of files
  # Make a graph
  g = DiGraph(length(nodes))
  for (parent, included) in enumerate(edges)
    for child in findin(nodes, included)
      add_edge!(g, parent, child)
    end
  end
  return g, nodes
end

"""Finds include statements inside a file"""
function find_includes(file_path::AbstractString)
  file_dir = splitdir(file_path)[1]
  query = Selector(Any[x->isa(x,Expr), iscalling(:include)])
  ast = parse_file(file_path)
  exprs = parse_ast(ast, query)
  files = map(x->x.args[2], exprs)
  filter!(x->isa(x, AbstractString), files) # TODO warn or something
  map!(x->joinpath(file_dir,x), files)
  if !all(isfile, files)
    throw(IncludeError("Could not find $(files[map(!isfile, files)])"))
  end
  return files
end

function plot_tree(g::DiGraph, files::Array, filename)
  @assert !is_cyclic(g) "Your graph is cyclic"
  layout_tree(g.fadjlist, file_names; filename=filename, cycles=false, ordering=:barycentric)
end

function resolve_module() # This could get complicated to do statically. Look into doing it dynamically a la ThrowawayModules.jl?
end

end
