dir = splitdir(@__FILE__)[1]

include(joinpath(dir, "Static.jl"))
include(joinpath(dir, "ASTIdentification.jl"))
include(joinpath(dir, "Dynamic.jl"))
include(joinpath(dir, "filetrees.jl"))
include(joinpath(dir, "corpustools.jl"))
include(joinpath(dir, "TM.jl"))
# include(joinpath(dir, "DynAl.jl"))
