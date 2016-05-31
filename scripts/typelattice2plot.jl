using LightGraphs
using GraphLayout
using PlotlyJS
using Compose

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

push!(LOAD_PATH, pwd())
using Plots
using LightGraphs
import P
import DynAl
using Sparklines
using DataFrames

fdf = DataFrame()
fdf[:func] = # some set of functions
fdf[:g] = map(x->P.method_sig_lattice(collect(methods(x)))[1], fdf[:func].data)
fdf[:eperv] = map(x->ne(x)/nv(x), fdf[:g].data)
fdf[:ncomponents] = map(x->length(weakly_connected_components(x)), fdf[:g].data)
fdf[:meancomp] = map(x->mean(map(length,weakly_connected_components(x))), fdf[:g].data)
fdf[:indeghist] = map(x->sprint(spark,hist(indegree(x))[2]), fdf[:g].data)
fdf[:outdeghist] = map(x->sprint(spark,hist(outdegree(x))[2]), fdf[:g].data)
fdf[:modules] = map(DynAl.modules, fdf[:func].data)
fdf[:methods] = map(x->methods(x).ms, fdf[:func].data)
fdf[:ambig] = map(DynAl.ambiguities, fdf[:func])



fdf[:func] = DynAl.get_something(Main, Function, true)
fdf[:func] = filter(x->length(collect(methods(x)))>0, DynAl.get_something(Main, Function, true))
fdf = fdf[sortperm(fdf[:g].data, by=nv, rev=true),:]


mdf = by(fdf, :func, x->collect(DynAl.module_methods(x[1,:func], DynAl.get_modules(Base.LinAlg, true))));
rename!(mdf,:x1,:method);
mdf[:method] = convert(DataArray{Method}, mdf[:method]);


function anyambiguity(m1::Method, m2::Method)
    s1 = m1.sig
    s2 = m2.sig
    ti = typeintersect(s1, s2)
    if ti === Bottom
        false
    elseif ti === s1 || ti === s2
        false
    else
        true
    end
end

adf = by(mdf, :func) do subdf
   ms = subdf[:method].data
   ms = collect(filter(x->anyambiguity(x...), Base.combinations(ms, 2))) # Finding ambiguous methods.
   ms = map(x->typeintersect(x[1].sig,x[2].sig), ms) # ambiguious points
   if length(ms) > 0
       cs = combinations(ms,2)
       cs = collect(filter(x->DynAl.are_same_type(x...), cs))
       if length(cs) > 0
           cs = collect(Base.flatten(cs))
           ms = ms[findin(ms, cs)]
        #    delete!(ms, cs)
       end
       ms
       # collect(Base.flatten(filter(x->DynAl.are_same_type(x...), combinations(adf[:x1],2))))
   else
       ms
   end
end

func_to_plot = \
types = map(x->x.sig, DynAl.module_methods(func_to_plot, DynAl.get_modules(Base.LinAlg, true)))
types = convert(Vector{Type}, types)
orig_length = length(types)
append!(types, adf[adf[:func] .== func_to_plot, :x1].data)
push!(types, Union{})
g, t_names = P.type_graph(types)
for_colors = fill(1, orig_length) # Natural signatures
append!(for_colors, fill(2, length(types) - orig_length -1)) # Ambiguities
push!(for_colors, 3) # Union{}
colors = P.make_colors(for_colors)
P.plot_with_color("forwardslash_sig-plusambig", g, t_names, colors)

"""
Gets unique set of elements by comparison `comp`

If two elements are equal by `comp`, only one will appear in output set.
"""
function uniqueby(a, comp::Function)

end


function type_df(a::Array)
   ts = DataFrame()
   ts[:type] = a
   ts[:abstract] = map(field(:abstract), ts[:type])
   ts[:leaf] = map(isleaftype, ts[:type])
   ts[:params] = map(field(:parameters), ts[:type])
   ts[:fields] = map(field(:types), ts[:type])
   ts[:n_methods] = map(ts[:type]) do x
       try length(methodswith(x))
       catch err
           C.EmptyField()
       end
   end
   return ts
end
