# This script does some dynamic analysis of module usage

# Import all packages, to run when I have more time
not_imported = Symbol[]
for pkg in map(symbol, keys(Pkg.installed()))
   try
     require(pkg)
   catch x
     try
       Pkg.checkout(string(pkg))
       require(pkg)
       map(require, Pkg.dependents(pkg))
     catch x
       warn(x)
       println(pkg)
       push!(not_imported, pkg)
       continue
     end
   end
end
# Import all packages
not_imported = Symbol[]
import_troubles = Symbol[]
imported = Module[]
to_import = map(Symbol, keys(Pkg.installed()))
req_reqs = map(Symbol, Pkg.dependents("Requires"))
append!(deleteat!(to_import, findin(to_import, req_reqs)),req_reqs)
filter!(x->!(x in [:Escher, :QuantumLab, :VegaLite, :Matcher]), to_import) # Don't import problematic packages
for pkg in to_import
    pkg in names(Main) ? continue : nothing
   try
     require(pkg)
   catch x
     try
       require(pkg)
       println("importing $pkg worked on second try.")
     catch y
       warn(y)
       print_with_color(:red, string(pkg))
       push!(not_imported, pkg)
     end
     push!(import_troubles, pkg)
   end
   if :Escher in names(Main)
     print_with_color(:magenta, "Escher found in Main after trying to import $pkg")
     break
   end
end



# Get all modules which got imported
# imported = filter(x->isa(x, Module), map(eval, names(Main)))
# imported = convert(Array{Module, 1}, imported)
# submodules = []
function Pkg.rm(pkg::String, force::Bool)
  if force
    rm(Pkg.dir(pkg); recursive=true)
  else
    Pkg.rm(pkg)
  end
end

function Pkg.checkout(pkg::String, force::Bool)
  if force
    cd(Pkg.dir(pkg)) do
      run(`git pull`)
    end
  else
    Pkg.checkout(pkg)
  end
end

imported = Module[]
for name in intersect(map(symbol, Pkg.available()), names(Main))
  e = try
    eval(name)
  catch x
    warn(x)
    continue
  end
  isa(e, Module) ? push!(imported, e) : nothing
end
filter!(x->length(names(x))>1, imported)
# Find out what modules they have in them.
# for i in imported
#   contents = names(i)
#   econtents = map(contents) do c
#     out = try
#       eval(i,c)
#     catch x
#       if isa(x, UndefVarError)
#         c
#       else
#         rethrow(x)
#       end
#     end
#     out
#   end
#   push!(submodules, filter(x->isa(x,Module), econtents))
#  end

# Counting that
 counter(map(length, submodules))

make_graph(pkg::AbstractString) = run(`julia-dev scripts/type_graph.jl $(pkg)`)
plot_graph(pkg::AbstractString) = run(`julia scripts/typelattice2plot.jl $(pkg)`)

inpkg(t::Type, pkg::Module) = contains(repr(t), repr(pkg)) # this probably won't get typeconstructors or unions
# function inpkg(t::type, pkg::Module)
#   ms = ddf[ddf[:pkg].==pkg][:modules]
#   ms_types = union(ddf[findin(ddf[:pkg],ms)][:types]...)
# I need to be able to make sure that these things are unique
ddf = DataFrames.DataFrame()
ddf[:pkg] = filter(x->length(names(x))>1, imported)
ddf[:alltypes] = map(x->DynAl.get_something(x, Union{DataType, TypeConstructor}, true), ddf[:pkg]) # contains some imported types
ddf[:types] = map(x->filter(y->inpkg(y, ddf[x,:pkg]), ddf[x,:alltypes]), 1:size(ddf)[1]) # May not contain typeconstructors/ unions
ddf[:exported] = map(x->DynAl.get_module_contents(x, true), ddf[:pkg])
ddf[:modules] = map(x->DynAl.get_modules(x, true), ddf[:pkg])
#=
If I know all the functions and types in a package, I could infer what packages it requires by getting that info out of Method.module and eval(Symbol(split(repr(Type), ".")[1]))
=#
# ddf[:abstract] = map(x->reduce(+, 0,map(field(:abstract),filter(_->isa(_, DataType), x))), ddf[:types])
ddf[:abstract] = map(x->filter(z->z.abstract, filter(y->isa(y,DataType), x)), ddf[:alltypes])
ddf[:leaf] = map(x->filter(isleaftype, x), ddf[:alltypes])
ddf[:unions] = map(x->DynAl.get_something(x, Union, true), ddf[:pkg])
# ddf[:module_names]
ddf[:functions] = map(x->DynAl.get_something(x, Function, true), ddf[:pkg]) # this has started taking a reaaaaly long time.
ddf[:methods] = map(i->collect(filter(y->y.module in ddf[i,:modules] ,Base.flatten(map(x->methods(x), ddf[i,:functions])))), 1:size(ddf)[1]) # Some of these are not unique
ddf[:method_sigs] = map(x->map(x->field(x,[:sig,:parameters])[2:end], x), ddf[:methods])
# ddf[:methods] = map(x->map(y->collect(methods(y)), ddf[x,:functions]), ddf[:functions])
ddf[:exported_types] = [filter(_->isa(_, Union{DataType, TypeConstructor}), x) for x in ddf[:exported]]
ddf[:exported_functions] = [filter(_->isa(_, Function), x) for x in ddf[:exported]]
ddf[:exported_methods] = map(1:size(ddf)[1]) do i
  fs = ddf[i, :exported_functions]
  if length(fs) == 0
    return Method[]
  end
  ms = Base.flatten(map(methods, fs))
  convert(Array{Method,1},unique(filter(x->field(:module)(x) in ddf[i,:modules], ms)))
end
# filter(x->field(x,:module) in ddf[i,:modules], Base.flatten(map(i->map(methods,(ddf[i, :exported_functions]), ddf[:exported_functions])))
ddf[:tcs] = map(x->DynAl.get_something(x, TypeConstructor, true), ddf[:pkg])
# ddf[:tcs] = map(x->DynAl.get_something(x
ddf[:type_params] = map(ts->map(t->t.parameters, ts), ddf[:types]) # Includes TypeConstructors
# ddf[:type_params] = map(ts->map(t->t.parameters, filter(x->isa(x,DataType), ts)), ddf[:types])
# temp = map(length, pdf[Bool[x!=[] for x in pdf[:tcs]],:tcs])
# temp = convert(Array{Int}, temp)
# UnicodePlots.histogram(temp; bins=20)
# temp = convert(Array{Int}, map(length, pdf[:types]))
tdf = DataFrame()
tdf[:type] = Base.flatten(pdf[:types])
# pdf[:]
map(length, pdf[:datatypes])

within(x::DataType) = isleaftype(typeof(x))

line_count(file::AbstractString) = parse(split(readstring(`wc -l $file`))[1])
pkg_files(pkg::AbstractString) = map!(chomp, readlines(`find $(joinpath(Pkg.dir(pkg), "src")) -name *.jl`))

edf = DataFrame()
edf[:pkgname] = map(repr, ddf[:pkg])
edf[:nlines] = map(x->sum(map(line_count, pkg_files(x))), edf[:pkgname].data)
edf[:ntypes_all] = map(length, ddf[:alltypes])
edf[:ntypes] = map(length, ddf[:types])
edf[:nabstract] = map(length, ddf[:abstract])
edf[:nleaftypes] = map(length, ddf[:leaf])
edf[:ntypeconstructors] = map(length, ddf[:tcs])
edf[:nunions] = map(length, ddf[:unions])
edf[:nmodules] = map(length, ddf[:modules])
edf[:ntypes_exported] = map(length, ddf[:exported_types])
edf[:nfunctions] = map(length, ddf[:functions])
edf[:nfunctions_exported] = map(length, ddf[:exported_functions])
edf[:nmethods] = map(length, ddf[:methods])
edf[:nmethods_exported] = map(length, ddf[:exported_methods])
edf[:nmethod_params] = map(x->length(collect(Base.flatten(x))), ddf[:method_sigs])
edf[:nmethod_params_unique] = map(x->length(unique(Base.flatten(x))), ddf[:method_sigs])
edf[:nmethod_params_leaf] = map(x->length(collect(filter(y->isleaftype(y), Base.flatten(x)))), ddf[:method_sigs])
edf[:nmethod_params_union] = map(x->length(collect(filter(y->isa(y,Union), Base.flatten(x)))), ddf[:method_sigs])
edf[:nmethod_params_abstract] = map(x->length(collect(filter(y->field(y,:abstract) == true, Base.flatten(x)))), ddf[:method_sigs])
edf[:nmethod_params_tcs] = map(x->length(collect(filter(y->isa(y, TypeConstructor), Base.flatten(x)))), ddf[:method_sigs])
edf[:nmethod_params_fieldy] = map(x->length(collect(filter(y->field(y,:abstract) == false, Base.flatten(x)))), ddf[:method_sigs])
edf[:ntypeparams] = map(x->length(vcat(x...)), ddf[:type_params])
# edf[:ntypeparams_sqrd] = map(x->reduce(+,map(y->length(y)^2,x))/length(x), ddf[:type_params])
# edf[:ntypeparams_sqrd] = map(x->sum(map(y->length(y)^2,x))/length(x),ddf[:type_params])
edf[:ntypeparams_sqrd] = map(ddf[:type_params]) do x
  if length(x) == 0
    NaN
  else
    sum(map(y->length(y)^2, x))/length(x)
  end
end

counter(map(nv, fdf[:g].data)).map |> collect |> sort # quick count of methods per function
