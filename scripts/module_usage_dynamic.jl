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


# Get all modules which got imported
imported = filter(x->isa(x, Module), map(eval, names(Main)))
imported = convert(Array{Module, 1}, imported)
submodules = []

imported = Module[]
for name in intersect(map(symbol, Pkg.available()), names(Main))
  e = try
    eval(name)
  catch x
    warn(x)
    continue
  end
  isa(e, Module) ? push!(imported, e)
end
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
