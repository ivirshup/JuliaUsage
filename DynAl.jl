module DynAl
get_types(m::Module, recursive::Bool=false) = get_something(m::Module, Type, recursive)
get_modules(m::Module, recursive::Bool=false) = get_something(m::Module, Module, recursive)

"""Returns all values of type "thing" in module"""
function get_something(m::Module, thing::Type, recursive::Bool=false)
  econtents = recursive ? get_module_contentsr(m) : get_module_contents(m)
  filter(x->isa(x,thing), econtents)
end

"""Gets and evals all contents of a module"""
function get_module_contents(m::Module)
  econtents = map(names(m, true)) do c
    out = try
      eval(m,c)
    catch x
      if isa(x, UndefVarError)
        c
      else
        rethrow(x)
      end
    end
    out
  end
  return econtents
end

"""Gets module contents, recursing into contained modules"""
function get_module_contentsr(m::Module, visited=Set{Module}())
  if m in visited
    return []
  end
  push!(visited, m)
  contents = get_module_contents(m)
  for c in copy(contents)
    # println(c)
    if isa(c, Module) && module_parent(c) === m && module_name(c) != :Core # Gives UndefRefError, and not really relevant to current work
      # println("Found module $(c) in module $(m).")
      append!(contents, get_module_contentsr(c, visited))
    end
  end
  # return unique(contents)
  return contents
end

"""Adds a package with error checking"""
function add_package(name)
  try
    Pkg.add(name)
  catch x
    warn(x)
    name
  end
end

fieldtypes(t) = map(x->fieldtype(t,x), fieldnames(t))

function fieldtypedict(t)
  d = Dict{Symbol, Union{Type,TypeVar}}()
  for field in fieldnames(t)
    d[field] = fieldtype(t, field)
  end
  return d
end

end
# t = DataFrame()
# t[:type] = DynAl.get_something(Main, DataType, true)
# by(t, :type) do subdf
#  entry_type = subdf[1,:type]
#  entry_fields = fieldnames(entry_type)
#  entry_fields_types = map(x->fieldtype(entry_type, x), entry_fields)
#  DataFrame(field = entry_fields, field_type = entry_fields_types)
# end
# t[:immut] = [!x.mutable for x in t[:type]]
# t[:param] = [x.param for x in t[:type]]
# t[:]

# paramed = t[map(length, t[:params]) .> 0,:]
# map(x->map(isleaftype, x), paramed[:params]) |> x->map(all, x) |> sum
