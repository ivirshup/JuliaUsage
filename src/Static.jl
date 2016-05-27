module Static

export Selector, EmptyField,
       parse_ast, filter_ast, filter_ast!, map_ast, map_ast!,
       field, hasfield,
       parse_file, count_exprs
###
### File handling
###
"""Downloads repo to dest

Usage:
```julia
repo_dir = "/Users/isaac/Documents/julia_repos/"
packages = Pkg.available()
pkg_repo = map(x->[Pkg.Read.url(x), string(repo_dir,x)], packages)
a = distribute(pkg_repo)
b = map(x->download_repo(x...), a)
gather(Context(), b)
```
"""
function download_repo(pkg_url, pkg_dest)
  try
    run(`git clone $(pkg_url) $(pkg_dest)`)
  catch x
    if isa(x, LoadError)
      println(x) # I should probably log these
      pass
    else
      throw(x)
    end
  end
end

"""Recursivley searches directories within passed one to find julia files"""
function search_dirs(base_dir::AbstractString,
           files::Array{AbstractString,1}=Array{AbstractString,1}())
  dir_queue = map(x->joinpath(base_dir, x), readdir(base_dir))
  for entity in dir_queue
    if isfile(entity) && entity[end-2:end]==".jl"
      push!(files, entity)
    elseif isdir(entity)
      append!(files, search_dirs(entity))
    end
  end
  return files
end

parse_file(file::IO) = parse_file(readstring(file))
"""Parse a file into expressions"""
function parse_file(file_path::AbstractString)
  if length(file_path) < 100 && isfile(file_path) # Probably change this (isfile errors w long strings)
    contents = readstring(file_path)
  else
    contents = file_path
  end
  exprs = []
  i = start(contents)
  while !done(contents, i)
    try
      ex, i = parse(contents, i) # TODO see if I can get JuliaParser working
      push!(exprs, ex)
    catch x
      warn("""File "$(file_path)" raises error: \n$(x)""")
      println("""File "$(file_path)" raises error: \n$(x)""")
      return [] # Come up with non failing way to parse file later # how do I update i?
    end
  end
  exprs
end
# function parse_file(file_path::AbstractString)
#   contents = readstring(file_path) # Basically treating it as a stream
#   exprs = []
#   i = start(contents)
#   while !done(contents, i)
#     ex, i = parse(contents, i) # TODO see if I can get JuliaParser working
#     push!(exprs, ex)
#   end
#   exprs
# end


using DataStructures

###
### 🍖🍖🍖
###

"""Singleton value to show no value could be found"""
type EmptyField
end

"""Ways to get values/ nested field values without throwing errors."""
:field

"""Returns a function which can be used to filter content based on fields.

field(field_accesor)(ast)
"""
# field(s::Symbol) = x->isdefined(x, s) ? getfield(x,s) : EmptyField()
field(s::Symbol) = x->hasfield(x, s) ? getfield(x,s) : EmptyField() # isdefined does not work with arrays.
field(i::Int) = x->isdefined(x, i) ? x[i] : EmptyField()
# field(nested::Array{Union{Symbol, Int}}) = x->reduce((a,b)->field(b)(a), x, nested)
field(nested::Array) = x->reduce((a,b)->field(b)(a), x, nested)
"""field(ast, fieldname)"""
field(x, test::Union{Array, Symbol, Int}) = field(test)(x)

"""Possibly not needed"""
hasfield(t::Type, f::Symbol) = f in fieldnames(t)
hasfield(t, f::Symbol) = hasfield(typeof(t), f)
# hasfield(t, f::Int) =

"""Stores boolean tests for fields"""
type Selector
  tests::Array{Union{Function, Array{Function}}}
end

"""Bool for if all tests pass"""
function (x::Selector)(arg) # Could probably clean this up with a while pass == true
  passes = Bool[]
  for test in x.tests
    t = typeof(test)
    # println(test, t, t <: Function)
    if t <: Array{Function}
      state = arg
      for i in test # reduce((a,b)->b(a), arg, test) # But with check for EmptyField
        state = i(state) # Might allow for side effects
        if state == EmptyField()
          return false
          break
        end
      end
      @assert isa(state, Bool)
      !state && return false
      # if state == false; return false; end
    elseif t <: Function
      result = try
        test(arg)
      catch err
        warn(err)
        return false
      end
      if (result == false) | (result == EmptyField())
        return false
      end
    else
      warn("Unrecognized t", t)
    end
  end
  return true
end

"""
Traverses AST returning relevant values (queried with selector)

parse_ast(ast, s::Static.Selector)
""" # TODO: Should this just take a `Union{Expr, AbstractArray}`?
function parse_ast(ast, s::Union{Static.Selector, Function}, exprs::Array=[]) #TODO could/ should I replace s with Union(Selector, Function)?
  t = typeof(ast)
  if t <: Array
    for i in ast
      parse_ast(i, s, exprs)
    end
  elseif s(ast)
    # println("I should be adding $(ast) to returned array.")
    push!(exprs, ast)
    # println(exprs)
  end
  if t <: Expr # Actually, might # TODO this won't explore everything
    parse_ast(ast.args, s, exprs) # Not terribly disimilar from filtering
  end
  exprs
end
"""Returns all expressions in AST""" # Legacy, at this point
function parse_ast(ast, exprs::Array{Expr,1}=Expr[])
  t = typeof(ast)
  if t <: Array
    for i in ast
      parse_ast(i, exprs)
    end
  elseif t <: Expr
    push!(exprs, ast)
    parse_ast(ast.args, exprs)
  end
  exprs
end

"""Return ast with same shape, filtered by f."""
function filter_ast(f::Function, ast)
    ast2 = deepcopy(ast)
    filter_ast!(f, ast2)
end
function filter_ast!(f::Function, ast)
    !f(ast) && return EmptyField()
    t = typeof(ast)
    if t <: AbstractArray
        filter!(x->!isa(filter_ast!(f,x), EmptyField),ast)
    elseif t <: Expr
        results = filter_ast!(f, ast.args)
    end
    return ast
end

"""Modify AST inplace."""
function map_ast!(f::Function, s::Union{Selector, Function}, expr::Union{Expr, Array})
  matching = parse_ast(expr, s)
  map!(f, matching)
  return expr
end
function map_ast(f::Function, s::Union{Selector, Function}, expr::Union{Expr, Array})
  expr2 = deepcopy(expr)
  map_ast!(f, s, expr2)
end

###
### :octocat::octocat::octocat:
###

# function blame(lnn::LineNumberNode)
#   line = lnn.line
# end

###
### Summary + convenience
###

"""Counts types of expressions found in list"""
function count_fields(exprs::AbstractArray)
  d = DefaultDict{Symbol, Int, Int}(0)
  h = map(x->x.head, exprs)
  for i in h
    d[i] += 1
  end
  d
end

"""Basic processing for a .jl file"""
function process_file(path::AbstractString, s::Static.Selector)
  ast = parse_file(path)
  exprs_list = parse_ast(ast, s)
  count_fields(exprs_list)
end
function process_file(path::AbstractString)
  ast = parse_file(path)
  exprs_list = parse_ast(ast)
  count_fields(exprs_list)
end

"""Collect dictionaries returned by gather(count_exprs)"""
function collect_dicts(a::Array{Any, 1})
  d = DefaultDict{Symbol, Int, Int}(0)
  for i in a
    for j in i
      for (k,v) in j
        d[k] += v
      end
    end
  end
  d
end

# TODO generalize
function count_exprs(files)
  a = distribute(files)
  b = map(x->process_file(x), a)
  return collect_dicts( gather(Context(), b).xs)
end
count_exprs(files, s::Selector) = pmap(x->parse_ast(parse_file(x), s), files)
end
