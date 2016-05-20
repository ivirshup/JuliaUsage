module DynAl
get_types(m::Module, recursive::Bool=false) = get_something(m::Module, Type, recursive)
get_modules(m::Module, recursive::Bool=false) = get_something(m::Module, Module, recursive)

"""Returns all values of type "thing" in module"""
function get_something(m::Module, thing::Type, recursive::Bool=false)
  econtents = recursive ? get_module_contentsr(m) : get_module_contents(m)
  filter!(x->isa(x,thing), econtents)
  return unique(convert(Array{thing,1}, econtents))
end

"""Gets and evals all contents of a module"""
function get_module_contents(m::Module, exported::Bool=false, imported::Bool=false)
  econtents = map(names(m, !exported, imported)) do c
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
  # return unique(contents) # Why did I replace this?
  return contents
end

# Another possible direction
# function get_required(m::Module)
#   ts = get_types(m, true)
#   filter(z->z in names(Main), map(y->split(y, ".")[1], filter(x->contains(x, "."), map(repr, ts))))
#   ms = get_modules(m, true)
#   unique(ms)
#   fs = Base.flatten(map(methods, get_something(m, Function, true)))
#   unique(map(x->x.module, fs))
# TODO these aren't working quite right
"""
Returns a list of modules which are dependencies of the `m`.
"""
function get_required(m::Module)
  all_contents = get_required2(m)
  acceptable_parents = [m, Main, get_modules(m, true)...]
  # filter!(x->x in Set([Main, Core, Base]), all_contents)
  setdiff!(all_contents, [Main, Core, Base])
  # return Array(x->isa(x, Module), all_contents)
  return filter(x->module_parent(x) in acceptable_parents, all_contents)
end

function get_required2(m::Module, visited=Set{Module}())
  println(m)
  push!(visited, m)
  contents = Set{Module}(filter(x->isa(x,Module), get_module_contents(m, false, true)))
  for c in copy(contents)
    if isa(c, Module) && !(c in visited)
      union!(contents, get_required2(c,visited))
    end
  end
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

get_exported(m::Module) = get_module_contents(m, true)

import Base.module_name

module_name(x::TypeName) = x.module
module_name(x::Type) = module_name(x.name)
# module_name(x::TypeConstructor) = # TODO
# name(x::DataType) = x.name

"""
  explore_type_tree(DenseArray)

Get all types which inherit from `x`
"""
function explore_type_tree(x::DataType)
  new_ts = subtypes(x)
  union([x], map(explore_type_tree, filter(x->!isleaftype(x), new_ts))...)
end


# tcs = DynAl.get_something(Main, TypeConstructor, true)

"""
  add_tcs(explore_type_tree(x), tcs)

Adds type constructors to a list of type(as they aren't found by `subtypes(x)`),
representing a type tree.
"""
function add_tcs(types::AbstractArray, tcs::AbstractArray)
  union(types, filter(x-> x<:Union{types...}, tcs))
end

# dependent_param(x::DataType) = x <: Val
# dependent_param(x::TypeConstructor) = any(dependent_param, x.body)
# param(x::DataType) = x <: Val || any(param, x.types)
# param(x::TypeVar) = param(x.ub)
# param(x::Union) = any(param, x.types)
# param(x::TypeConstructor) = any(param, vcat(x.body, x.parameters...))


"""
Checks to see if this method was exported to the top level
"""
isexported(x::Method, m::Module=Main) = x in methods(eval(Main, x.name))
# isexported(x::Method) = isexported(x, x.module)

import Base.return_types
function return_types(m::Method)
  linfo = m.func
  atypes = Base.to_tuple_type(m.sig)
  if !isa(m.tvars, SimpleVector)
      sparams = Base.svec(m.tvars)
  else
      sparams = m.tvars
  end
  @assert isa(sparams, SimpleVector)
  # I think I need to get m.tvars into a SimpleVector
  (_li, ty) = Core.Inference.typeinf(linfo, atypes, sparams) # Retuns `(lowered, return_type)`
  ty
end
"""
Trys to infer which types a method could return.
"""
function return_types(m::TypeMapEntry)
    linfo = m.func
    atypes = Base.to_tuple_type(m.sig)
    if !isa(m.tvars, SimpleVector)
        sparams = Base.svec(m.tvars)
    else
        sparams = m.tvars
    end
    @assert isa(sparams, SimpleVector)
    # I think I need to get m.tvars into a SimpleVector
    (_li, ty) = Core.Inference.typeinf(linfo, atypes, sparams) # Retuns `(lowered, return_type)`
    ty
end
# return_types(type_mt[end-1])
return_types(x::LambdaInfo) = x.rettype
return_types(x::Method) = return_types(x.lambda_template)

"""
Returns the types in a methods signature in an array.

Seems to be returning for real parametric types?
"""
method_sig_types(m::Method) = m.sig.parameters[2:end]
method_sig_types(a::AbstractArray) = Base.flatten(map(method_sig_types, a))

# It's hard to make the return of this unique, yielding
# These are the ones I want to get rid of:
# types = unique(temp2)
# temp3 = filter(x->issubtype(x[1],x[2]) && issubtype(x[2],x[1]), permutations(types, 2))
# temp3 = unique(Base.flatten(temp3))
# findin(temp2, temp3)
are_same_type(t1, t2) = t1 <: t2 && t2 <: t1
"""
Get all methods from a module
"""
function module_methods(m::Module, recurse::Bool=true)
  mods = recurse ? get_modules(m, true) : [m]
  println(mods)
  fs = get_something(m, Function, recurse)
  ms = Base.flatten(map(x->collect(methods(x)), fs))
  ms = filter(x->x.module in mods, ms)
  return ms
end

"""
Returns a unique lists of types.

Two types `T1`, `T2` are considered the same if `T1 <: T2 <: T1`.
"""
function unique_types(types::AbstractArray)
  old_types = copy(types) # To prevent side effects
  new_types = []
  while length(old_types) != 0
    t = pop!(old_types)
    filter!(x->!are_same_type(x,t), old_types)
    push!(new_types, t)
  end
  return new_types
end
unique_types(types::Base.Flatten) = unique_types(collect(types))
# unique(Base.flatten(map(method_sig_types, module_methods)))
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
#
