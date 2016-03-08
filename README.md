Project for looking at how people use Julia.

# TODO

Roughly sorted in order of priority

* [ ] Associate code with Users
  * [ ] Get git info (mostly `blame`) out of files.
    * `git blame -L$(ln_start),$(ln_end)` should do it, but there may be ambiguous changes
* [ ] Be able to evaluate code
* [x] Better plot, maybe interactive
  * [x] Values should be fraction of statements I think
* [x] Get queries working, maybe rethink?
* [x] Tests!
  * [ ] Better tests! Maybe types, or line number nodes?
* [ ] Figure out `ComputeFramework.reduce`

# Issues

* JuliaParser doesn't seem to allow for reading starting from wherever
  * I tried to fix it, but am getting a weird error
* What gets fed the list that does code lowering? Can I pass an expression?
  * [docs](https://github.com/JuliaLang/julia/blob/a6992dd4d2ca08601afaaabb55fd52cef5a76a76/doc/devdocs/eval.rst)
  * [code for `parse()`](https://github.com/JuliaLang/julia/blob/master/base/parse.jl)
  * `Expr |> eval |> code_typed`?

# Features

* Added improved `Selector`, provides a big speed boost.
  * Chained expressions go in nested Arrays
  * Using `field(f::Symbol)`, symbols can be accessed safely. Returns false instead of error.
  * `field(a::Array)` allows for searching nested variables, including those in arrays by `field(i::Int)`
  * `field` can be called `field(test)(x)` or `field(x, test)`

```julia
Selector(Any[[C.field(:x), x->x==1], x->typeof(x) == Expr])
