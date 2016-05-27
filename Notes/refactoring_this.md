Where I will be laying out what I need to do in my refactor.

# Files I want to keep stuff from

* DynAl
* C --> Static.jl
* P
* ASTp
* FileTrees, but I could probably refactor it a lot.
  * I should probably try to get include statments out of a macro expanded thing? But then they are probably in a loop. I
  * I should make it easy to statically analyze a Pkg
*

# Things that need tests

* DynAl

# I should make examples, probably beyond scripts

* [ ] See if IJulia is working yet
* [ ] How should I be getting line counts from packages for Jan?
* [ ] Get tests working + write tests for DynAl

# Renaming

```julia
using JuliaUsage
import Dynamic, Static
```
```julia
import JuliaUsage.Dynamic
import JuliaUsage: Dynamic, Static
```
src/
  JuliaUsage.jl
  Dynamic.jl
  Static.jl
  Util.jl (fields)
  Metadata.jl/ DataOps.jl
  RepoMgmt.jl (Github stuff?)
  plotting/
    FileTrees.jl
    TypeTrees.jl
    TreeGraphics.jl


`using JuliaUsage`
* DynAl --> DynamicAnalysis --> Dynamic
* C --> Static
*
