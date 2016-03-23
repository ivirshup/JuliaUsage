# This script will unzip a repo, grep through it, delete the unziped repo, return a dict of terms.
addprocs(10)
# @everywhere pth = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage"
@everywhere pth = "/home/ivirshup/JuliaUsage/"
push!(LOAD_PATH, pth)
import SearchRepos
import GetData

@everywhere terms = collect(keys(GetData.find_dependents("ForwardDiff")))
# @everywhere repo_pth = joinpath(pth, "data", "repos")

# """Returns list of repos"""
# @everywhere repos() = filter(x->contains(x, ".zip"), readdir(repo_pth))

#"""Renames repos not matching correct filetype."""
function filter_repos()
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

# """pmap(search_repo, repos{full paths})"""
@everywhere function search_repo(repo, terms::Array)
  repo_pth = GetData.repo_pth
  d = Dict()
  d[repo] = Dict()
  rd_name = try
    SearchRepos.unzip(repo, repo_pth)
  catch x
    warn(x)
    println(repo)
    return d
  end
    # rd_name = SearchRepos.unzip(joinpath(repo_pth, r), repo_pth)
  println(rd_name)
  println(joinpath(repo_pth, rd_name))
  for t in terms
    d[repo][t] = length(SearchRepos.term_usage(joinpath(repo_pth, rd_name), t))
  end
  rm(rd_name; recursive=true)
  d
end

# println("Filtering repos")
# filter_repos()
# println("Filtered. Starting to parse.")
zips = map(x->joinpath("/home/ivirshup/JuliaUsage/data/repos", x), GetData.repos())
function main()
  d = pmap(x->search_repo(x, terms), zips)
  d = merge(d...)
  #serialize(open("repo_counts.jld", "w"), d)
  return d
end
