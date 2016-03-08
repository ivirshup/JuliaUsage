"""Working module"""

module C

using ComputeFramework

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

"""Parse a file into expressions"""
function parse_file(file_path::AbstractString)
  contents = readstring(file_path) # Basically treating it as a stream
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

"""Stores boolean tests for fields"""
type Selector
  tests::Array{Function}
end
"""Bool for if all tests pass"""
function (x::Selector)(arg)
  passes = Bool[] # Pretty sure it's okay to make this a bool
  for test in x.tests
    result = try
      test(arg)
    catch err
      # warn(err)
      # println(arg)
      push!(passes, false)
      break
    end
    push!(passes, result)
  end
  reduce(&, passes)
end

"""Traverses AST returning relevant values (queried with selector)"""
function parse_ast(ast, s::C.Selector, exprs::Array=[]) #TODO
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
function process_file(path::AbstractString, s::C.Selector)
  ast = parse_file(path)
  exprs_list = parse_ast(ast. s)
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

function count_exprs(files, s::Selector)
  a = distribute(files) # Maybe I should get the size of the files, then redistribute with large files going first?
  # b = map(x->process_file(x, s), a)
  b = map(x->parse_ast(parse_file(x),s), a)
  c = reduce(append!, [], gather(Context(), b).xs)
  reduce(append!, [], c)
  # return collect_dicts( gather(Context(), b).xs)
end

end
