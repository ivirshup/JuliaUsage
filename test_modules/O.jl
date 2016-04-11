"""A module to test stuff out in"""
module O
include("M.jl")
include("N.jl")
# Test functions to play around with

mod_o() = 3

function foo(x::Int)
  x + 1
end
foo(x) = x
foo(x::Int;y::Int=1) = x+y

function bar(x::Int)
  x += 1
  foo(x)
end

type Baz
  x::Int
end

foo(x::Union{Baz, Int}) = println(x)
foo(x::Baz) = x.x + 1
foo(x::Baz,y::Int=1) = x.x + y
bar(x::Baz) = foo(Baz.x += 1)
bar(x::Int) = Array([x,x,x])
# Parsing functions

export foo

 # Seeing if this is a viable path for building the cache
 # I would need to be able to get the name of this module



# function __init__() # This doesn't solve user defined fucntions, or script ones
#   println(current_module())
#   m = M
#   exported = names(m)
#   local_scope = names(m, true)
#   for i in local_scope
#     evalled = eval(m, i)
#     if isa(evalled, Function) # I'd like to only evaluate the methods defined here, which this won't allow
#
#     end
#
# end

end
