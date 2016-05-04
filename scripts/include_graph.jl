include("usage_setup.jl")

using FileTrees
using LightGraphs
using Escher
using NetworkViz

g, files = include_tree(base_files)

main(window) = begin
  push!(window.assets, "widgets")
  push!(window.assets,("ThreeJS","threejs"))
  drawGraph(g)
end
