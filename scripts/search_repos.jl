# This script will unzip a repo, grep through it, and zip it back up.
addprocs(10)
# @everywhere pth = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage"
@everywhere pth = "/home/ivirshup/JuliaUsage/"
push!(LOAD_PATH, pth)
import SearchRepos
import GetData

@everywhere terms = collect(keys(GetData.find_dependents("ForwardDiff")))
@everywhere repo_pth = joinpath(pth, "data", "repos")

# """Returns list of repos"""
@everywhere repos() = filter(x->contains(x, ".zip"), readdir(repo_pth))

#"""Renames repos not matching correct filetype."""
@everywhere function filter_repos()
  for f in repos()
    f = joinpath(repo_pth, f)
    if !contains(f, ".zip")
      continue
    end
    ftype = readstring(`file $f`)
    if !contains(ftype, "Zip archive data")
      file_name = splitext(f)[1]
      if contains(ftype, "HTML")
        mv(f, string(file_name, ".html"))
      elseif contains(ftype, "ASCII")
        mv(f, string(file_name, ".txt"))
      else
        println(f)
        println(ftype)
      end
    elseif !valid_zip(f)
      println(f)
    end
  end
end

# """search_repos(repos())"""
@everywhere function search_repo(repo, terms::Array)
  d = Dict()
  # for r in repo_list
  d[repo] = Dict()
  rd_name = try
    SearchRepos.unzip(joinpath(repo_pth, repo), repo_pth)
  catch x
    warn(x)
    println(repo)
    return d
  end
    # rd_name = SearchRepos.unzip(joinpath(repo_pth, r), repo_pth)
  println(rd_name)
  println(joinpath(repo_pth, rd_name))
  for t in terms
    d[repo][t] = length(SearchRepos.search_dir(joinpath(repo_pth, rd_name), t))
  end
  rm(rd_name; recursive=true)
  d
end

# println("Filtering repos")
# filter_repos()
# println("Filtered. Starting to parse.")
function main()
  d = pmap(x->search_repo(x, terms), repos())
  d = merge(d...)
  serialize(open("repo_counts.jld", "w"), d)
end
