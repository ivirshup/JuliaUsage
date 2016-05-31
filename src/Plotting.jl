module Plotting

using PlotlyJS
using GraphLayout
using LightGraphs
using Compose
using Lattice


function plot_graph(g, t_names)
  n = length(t_names)
  esced_names = map(Markdown.htmlesc, t_names)
  loc_x, loc_y, verts, arrows, adj_list = layout_tree_pos(g.fadjlist, esced_names)
  edges = edge_trace(adj_list, loc_x, -loc_y, 1)
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
  plot(p)
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

"""
Breaks string into bits to aid readability.
"""
function format_name(name::AbstractString)
    range = [i:min(i + 29, length(name)) for i in 1:30:length(name)]
    str = "<br>"
    println(range)
    for i in range
        println(str)
        str = str * Markdown.htmlesc(name[i]) * "<br>"
    end
    str
end

#TODO Clean this up
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

end
