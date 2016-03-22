addprocs(5)
# @everywhere pth = "/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/"
@everywhere pth = "/home/ivirshup/JuliaUsage/"
# push!(LOAD_PATH, pth)
import Requests
import SearchRepos

data = let f = open(joinpath(pth, "data", "julia_repos.jld"), "r")
  data = deserialize(f)
  close(f)
  return data
end

@everywhere out_path = joinpath(pth, "data/", "repos/")
if length(ARGS) == 2
  (idx1, idx2) = (parse(ARGS[1]), parse(ARGS[2]))
  println((idx1,idx2))
  data = data[idx1:idx2]
end

@everywhere function download_repo(repo, out_path)
    # if isdir(out_path)
    #     name = replace(repo, "/", "_")
    #     name = replace(name, "\.jl", "")
    #     name = string(name, ".zip")
    #     out_path = joinpath(out_path, name)
    # end
    # url = "https://github.com/$(repo)/zipball/master/"
    url, out_path = repo_pths(repo, out_path)
    s =Requests.get_streaming(url)
    println(url)
    f = open(out_path, "w")
    # println("starting to write")
    t0 = time()
    while !eof(s)
        write(f, readavailable(s))
        if time() - t0 > 20
            close(f)
            print_with_color(:red, "$(repo) download restarting.")
            return download_repo(repo, out_path)
        end
    end
    # println("done writing")
    return out_path
end

# """Given a repo name and directory create url and output path."""
@everywhere function repo_pths(repo, out_path)
  if isdir(out_path)
      name = replace(repo, "/", "_")
      name = replace(name, "\.jl", "")
      name = string(name, ".zip")
      out_path = joinpath(out_path, name)
  end
  url = "https://github.com/$(repo)/zipball/master/"
  return url, out_path
end

function check_repos

function main()
  println("I'll be putting files is $(out_path).")
  pmap(x->SearchRepos.download_repo(x, out_path), data)
end
