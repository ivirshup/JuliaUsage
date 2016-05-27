# Patterns for matching asts.
######################
# TODO
# * Possibly replace all dispatch based selections with filtering and type stable input.
# * Maybe make types? Then I can just set up my access to make sense.
module ASTp
using Static

export isfunction, isfunctiondecl, isanon,
       istypedecl, isconcretedecl, issingletondecl, isimmutabledecl,
       isabstractdecl, istypealias, isinheritance, isannotation,
       functionsig, functionbody, functionname,
       iscalling, iscall, isexpr,
       getcalls


isexpr(x) = isa(x, Expr)
"""Bool for if ast represents a function/method declaration""" # add do
function isfunction(expr::Expr)
  if isfunctiondecl(expr) || isanon(expr)
    x =true
  elseif field(expr, :head) == :(=)
    x = Selector(Any[[field([:args, 1, :head]), x->x==:call]])(expr)
  else
    x = false
  end
  return x::Bool
end
isfunction(not_an_expr::Any) = false

"""Bool for if AST is an anonymous function"""
isanon(expr::Expr) = expr.head == :->
isanon(not_an_expr::Any) = false

isfunctiondecl(expr::Expr) = expr.head == :function
isfunctiondecl(not::Any) = false

### Signatures

"""Returns parsed signature of a function declaration."""
function functionsig(expr::Expr)
  @assert isfunction(expr) "Need to pass function to retrieve function signature, passed $expr."
  if isanon(expr)
    isa(expr.args[1], Symbol) ? expr.args[1] : expr.args[1].args[2:end] # Symbol iff one arg
  else
    expr.args[1].args[2:end]
  end
end

"""Access function body of parsed function declaration."""
function functionbody(expr::Expr)
  @assert isfunction(expr) "Need to pass function to retrieve function body, passed $expr."
  return expr.args[2]
end

function functionhead(expr::Expr)
  @assert isfunction(expr)
  return expr.args[1]
end
function functionname(expr::Expr)
  name_field = functionhead(expr).args[1]
  if isa(name_field, Symbol)
    return name_field
  elseif field(name_field, :head) == :curly
    return name_field.args[1]
  else
    throw(error("Not sure what to do with $expr, was just looking for it's name?"))
  end
end

iscall(expr::Expr) = field(expr, :head) == :call
# TODO make these notice the difference between defining and using
iscalling(expr::Expr, funcs::Array{Symbol}) = iscall(expr) && field(expr, [:args, 1]) in funcs
iscalling(expr::Expr, func::Symbol) = iscall(expr) && field(expr, [:args, 1]) == func
iscalling(func_s::Union{Symbol, Array{Symbol}}) = x->iscalling(x, func_s) # TODO this might not be m

###
### 🍂🍃Types🍃🍂
###

# Declarations

"""Bool for if element represents a type"""
istypedecl(expr::Expr) = isconcretedecl(expr) || isabstractdecl(expr)

isconcretedecl(expr::Expr) = field(expr, :head) == :type
issingletondecl(expr::Expr) = isconcretedecl(expr) && length(field(expr, [:args,3,:args])) == 0
isimmutabledecl(expr::Expr) = isconcretedecl(expr) && field(expr, [:args, 1]) == false
isabstractdecl(expr::Expr) = field(expr, :head) == :abstract
istypealias(expr::Expr) = field(expr, :head) == :typealias

function isinheritance(expr::Expr)
  if isconcretedecl(expr)
    field(expr, [:args, 2, :head]) == :<:
  elseif isabstractdecl(expr)
    field(expr, [:args, 1, :head]) == :<:
  else
    false
  end
end
isinheritance(expr::Any) = false
# Working with types
# type_functions =

isannotation(expr::Expr) = field(expr, :head) == :(::)
isannotation(expr::Any) = false
# hastypesig()
# """
# Functions who recieve type information
#
# For type algebra
# """
# function type_sigs(files)
#     f(x) = C.parse_ast(x, C.Selector(Any[x->C.field(x, :head) == :(::)])) # Defines function globally
#     C.count_exprs(files,
#          C.Selector(Any[
#            x->C.field(x,:head)==:call,
#            x->length(C.field(x,:args)) >= 2,
#            [
#              C.field(:args),
#              x->x[2:end],
#              f,
#              x->length(x) > 0
#          ]]))
# end

# """Returns list of functions names called in an expression. Includes repeats.""" # TODO I'll need parent info for this
# getcalls(expr::Expr) = map(field([:args, 1]), parse_ast(expr, Selector([isexpr, iscall, x->!isfunction(x.parent)])))

# function getcalls(expr::Expr)
#   ast = filter_ast(x->!functionhead(x), expr)
#   map(field([:args,1]), parse_ast(ast, Selector([isexpr, iscall])))
# end
end
