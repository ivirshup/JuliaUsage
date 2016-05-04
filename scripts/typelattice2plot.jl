using LightGraphs
using GraphLayout
using PlotlyJS
using Compose

plt_name = ARGS[1]
plotting_dir = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/plotting/"
data_dir = joinpath(plotting_dir, "pkg_type_data")
out_pth = joinpath(plotting_dir, "pkg_type_plots", string(plt_name, ".html"))
# plt_name = "Escher"
# println(ARGS)

# name_pth = ARGS[2]
# data_pth = ARGS[3]
name_pth = joinpath(data_dir, string(plt_name, "_names.txt"))
graph_pth = joinpath(data_dir, string(plt_name, "_graph.lg"))

function layout_tree_pos(adj_list, labels;
                                xsep        = 10,
                                ysep        = 20,)
   n = length(adj_list)
   println(n)
   layers = GraphLayout._layer_assmt_longestpath(adj_list)
   num_layers = maximum(layers)
   println("Number of Layers: ", num_layers)
   println(layers)
   # 2.2  Create dummy vertices for long edges
   adj_list, layers = GraphLayout._layer_assmt_dummy(adj_list, layers)
   orig_n, n = n, length(adj_list)
   layer_verts = [L => Int[] for L in 1:num_layers]
   for i in 1:n
       push!(layer_verts[layers[i]], i)
   end
   println("layer_verts: ", length(layer_verts), " ", length(vcat(collect(values(layer_verts))...)))
   println("Makin' verts")
  #  layer_verts = _ordering_ip(adj_list, layers, layer_verts)
  #  layer_verts = GraphLayout._ordering_ip(adj_list, layers, layer_verts)
   layer_verts = GraphLayout._ordering_barycentric(adj_list, layers,
                 layer_verts)
    println("Made verts")
    println("layer_verts: ", length(layer_verts), " ", length(vcat(collect(values(layer_verts))...)))
   locs_y = zeros(n)
   for L in 1:num_layers
       for (x,v) in enumerate(layer_verts[L])
           locs_y[v] = (L-1)*ysep
       end
   end
       # 4.2   Get widths of each label, if there are any
   widths  = ones(n); widths[orig_n+1:n]  = 0
   heights = ones(n); heights[orig_n+1:n] = 0
   # Note that we will convert these sizes into "absolute" units
   # and then work in these same units throughout. The font size used
   # here is just arbitrary, and unchanging. This hack arises because it
   # is meaningless to ask for the size of the font in "relative" units
   # but we don't want to collapse to absolute units until the end.
   if length(labels) == orig_n
       extents = Compose.text_extents("sans",10pt,labels...)
       for (i,(width,height)) in enumerate(extents)
           widths[i]  = width.value
           heights[i] = height.value
       end
   end
   println("labels")
   locs_x = GraphLayout._coord_ip(adj_list, layers, layer_verts, orig_n, widths, xsep)
   # 4.3   Summarize vertex info
   max_x, max_y = maximum(locs_x), maximum(locs_y)
   max_w, max_h = maximum(widths), maximum(heights)
   println()
   verts = [GraphLayout._tree_textrect(locs_x[i], locs_y[i], labels[i], widths[i], heights[i]) for i in 1:orig_n]
   arrows = Any[]
   for L in 1:num_layers, i in layer_verts[L], j in adj_list[i]
       push!(arrows, GraphLayout._arrow_tree(
               locs_x[i], locs_y[i], i<=orig_n ? max_h : 0,
               locs_x[j], locs_y[j], j<=orig_n ? max_h : 0))
   end
   return locs_x, locs_y, verts, arrows, adj_list
end

function edge_trace(edge_list, loc_x, loc_y, node_radii)
   trace = scatter(x=[], y=[], mode="lines")
   trace["hoverinfo"] = "none"
   trace["showlegend"] = false
   trace["marker"] = Dict("size" => node_radii)#map(x->log(x["usage"])*6, values(deps)) )
   trace["line"] = Dict("color" => "#7E8AA2")
   for (n_idx, edge) in enumerate(edge_list)
     for e_idx in edge
       append!(trace["x"], [loc_x[n_idx], loc_x[e_idx], nothing])
       append!(trace["y"], [loc_y[n_idx], loc_y[e_idx], nothing])
     end
   end
   return trace
end

# function filter_edges(g, adj_list)
#   g2 = DiGraph(length(adj_list))
#   for (v1, edges) in enumerate(adj_list)
#     for v2 in edges
#       add_edge!(g2, v1, v2)
#     end
#   end
#   intersect(g2,g)
# end

# Load in data
g = open(graph_pth, "r") do f
   load(f)
end["digraph"]
t_names = open(name_pth, "r") do f
  map(chomp,readlines(f))
end
n = length(t_names)
# g = prune_tree(g)
# g = dfs_tree(g, findmax(map(length, g.fadjlist))[2])
esced_names = map(Markdown.htmlesc, t_names)


# Format
loc_x, loc_y, verts, arrows, adj_list = layout_tree_pos(g.fadjlist, esced_names)
# smaller_g = filter_edges(g, adj_list)
# edges = edge_trace(smaller_g.fadjlist, loc_x, -loc_y, 1)
edges = edge_trace(adj_list, loc_x, -loc_y, 1)


# plot
p = plot([
  edges,
  scatter(;x=loc_x[1:n], y=-loc_y[1:n], # Using 1:n as others are intermediate nodes
    text=esced_names,
    mode="markers",
    hoverinfo="text",
    marker=Dict(
    "color"=>"#FF9800",
    "size"=>10),
  ),
  ],
  Layout(;
    title=plt_name,
    height=1000)
)

savefig(p, out_pth; js=:local)


  # max_degree = Δ(g)
  # for v in g.vertices
  #   shared_w_p = map(x->common_neighbors(g, v, x), in_neighbors(g,v))
  #   println("$v $shared_w_p")
  # end
# function plot_tree(g::DiGraph)
