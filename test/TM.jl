push!(LOAD_PATH, joinpath(dirname(@__FILE__), "..", "src"), joinpath(dirname(@__FILE__), ".."))
using FactCheck

import ThrowawayModules

facts("ThrowawayModules") do
  context("Resolving paths to asts") do
    M = ThrowawayModules.new_module()
    compose_pth = Base.find_in_path("Compose", nothing)
    ds_pth = Base.find_in_path("DataStructures", nothing)
    compose_ast = ThrowawayModules.cleanfile(compose_pth, M)
    ds_ast = ThrowawayModules.cleanfile(ds_pth, M)
    @fact ThrowawayModules.resolve(:(import Compose), M) --> compose_ast
    # @fact ThrowawayModules.resolve(:(import DataStructures), M) --> ds_ast # Compose might have a requirement of DataStructures, so this won't actually evaluate.
    # @fact ThrowawayModules.resolve(:(import Compose, DataStructures), M) --> [compose_ast, ds_ast] # This would never be run
    # @fact ThrowawayModules.cleanast(:(import Compose, DataStructures), M) --> [compose_ast, ds_ast]
    # Loading specific things
    # Even when you try to import a specific thing,
    # @fact ThrowawayModules.resolve(:(import DataStuctures.DefaultDict))
    # @fact ThrowawayModules.resolve(:)

  end

  context("import/include/require") do
    # Setup
    M = ThrowawayModules.new_module()
    M_content = [
                    :(import Base.find_in_path), # Shouldn't re-include already loaded packages.
                    :(using Combinatorics), # Should bring appropriate names into namespace
                    :(module M_sub
                      export m
                      m = 1
                    end),
                    :(using .M_sub)
                    ]
    map(x->ThrowawayModules.load(M,x), M_content)
    # println(names(M, true))
    # println(ThrowawayModules.cleanast(M_content, M))
    # tests
    @fact_throws UndefVarError eval(:M_sub) # Variable scoping/ `using` resolution
    @fact M.M_sub.m --> 1
    @fact_throws UndefVarError eval(:find_in_path)
    @fact M.find_in_path("DataStructures") --> Base.find_in_path("DataStructures") # Method scoping
    @fact_throws UndefVarError eval(:npartitions)
    @fact_throws UndefVarError eval(:Combinatorics)
    @fact M.npartitions === M.Combinatorics.npartitions --> true # This is more a check to test for `npartitions` being imported
  end
end
