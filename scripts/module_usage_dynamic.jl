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
to_import = map(symbol, keys(Pkg.installed()))
filter!(x->!(x in [:Escher, :QuantumLab, :VegaLite]), to_import) # Don't import problematic packages
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
filter(x->length(names(x))>1, imported)
# Find out what modules they have in them.
for i in imported
  contents = names(i)
  econtents = map(contents) do c
    out = try
      eval(i,c)
    catch x
      if isa(x, UndefVarError)
        c
      else
        rethrow(x)
      end
    end
    out
  end
  push!(submodules, filter(x->isa(x,Module), econtents))
 end

# Counting that
 counter(map(length, submodules))

make_graph(pkg::AbstractString) = run(`julia-dev scripts/type_graph.jl $(pkg)`)
plot_graph(pkg::AbstractString) = run(`julia scripts/typelattice2plot.jl $(pkg)`)


pdf = DataFrames.DataFrame()
pdf[:pkg] = filter(x->length(names(x))>1, imported)
pdf[:types] = map(x->DynAl.get_something(x, Union{DataType, TypeConstructor}, true), pdf[:pkg])
pdf[:exported] = map(x->DynAl.get_module_contents(x, true), pdf[:pkg])
pdf[:modules] = map(x->DynAl.get_modules(x, true), pdf[:pkg])
# pdf[:module_names]
pdf[:function] = map(x->DynAl.get_something(x, Function, true), pdf[:pkg])
pdf[:exported_types] = [filter(_->isa(_, Union{DataType, TypeConstructor}), x[:exported]) for x in pdf[:exported]]
pdf[:exported_functions] = [filter(_->isa(_, Function), x) for x in pdf[:exported]]
pdf[:tcs] = map(x->DynAl.get_something(x, Union{DataType, TypeConstructor}, true), pdf[:pkg])
# temp = map(length, pdf[Bool[x!=[] for x in pdf[:tcs]],:tcs])
# temp = convert(Array{Int}, temp)
# UnicodePlots.histogram(temp; bins=20)
# temp = convert(Array{Int}, map(length, pdf[:types]))
# pdf[:]
map(length, pdf[:datatypes])

within(x::DataType) = isleaftype(typeof(x))
