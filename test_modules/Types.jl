###
### Types and subtypes
###

abstract AbstractFoo

type Foo <: AbstractFoo
  x::Type
  y::Int
end

type FooToo <: AbstractFoo
  x::Type
end

###
### Singletons
###

type Singleton
end

immutable iSingleton
end

###
### Type algebra
###

typeof(x)
isa(x, Foo)
bar(x::Foo, y::AbstractFoo) = convert(promote_type(typeof(x), typeof(y)), y)


# C.parse_ast(parse("""g(x::Int, y::AbstractString) = y * x"""),
#   C.Selector(Any[
#     x->C.field(x,:head)==:call,
#     x->length(C.field(x,:args)) >= 2,
#     [
#       C.field(:args),
#       x->x[2:end],
#       x->C.parse_ast(x, C.Selector(Any[x->C.field(x, :head) == :(::)])),
#       x->length(x) > 0
#   ]]))
