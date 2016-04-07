# Patterns for matching asts.
######################
# TODO
# * Possibly replace all dispatch based selections with filtering and type stable input.
module ASTp
using C

export isfunction, isfunctiondecl, isanon,
       istypedecl, isconcretedecl, issingletondecl, isimmutabledecl,
       isabstractdecl, istypealias, isinheritance
"""Bool for if ast represents a function/method declaration""" # add do
function isfunction(expr::Expr)
  if isfunctiondecl(expr) || isanon(expr)
    true
  elseif field(expr, :head) == :(=)
    Selector(Any[[field([:args, 1, :head]), x->x==:call]])(expr)
  else
    false
  end
end
isfunction(not_an_expr::Any) = false

"""Bool for if AST is an anonymous function"""
isanon(expr::Expr) = expr.head == :->
isanon(not_an_expr::Any) = false

isfunctiondecl(expr::Expr) = expr.head == :function
isfunctiondecl(not::Any) = false

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

# Working with
# type_functions =

end
