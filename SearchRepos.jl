module SearchRepos
using Requests

export download_repo, unzip, search_dir, search_repo, repo_pths, valid_zip

"""
Downloads zip of repo, returns path of file.

    download_repo("JuliaLang/julia", "out/")
"""
function download_repo(repo, out_path)
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

"""Given a repo name and directory create url and output path."""
function repo_pths(repo, out_path)
  if isdir(out_path)
      name = replace(repo, "/", "_")
      name = replace(name, "\.jl", "")
      name = string(name, ".zip")
      out_path = joinpath(out_path, name)
  end
  url = "https://github.com/$(repo)/zipball/master/"
  return url, out_path
end


"""Unzip file, return path of directory.

    unzip("JuliaLang_julia.zip", ".")
"""
unzip(path, out_dir) = split(chomp(readlines(`unzip -d $out_dir $path`)[3]))[end]
unzip(path) = split(chomp(readlines(`unzip $path`)[3]))[end]
# remove_repo(path) = rm(path; recursive=true)
search_dir(dir, term) = readlines(ignorestatus(`grep -r $term $dir`)) # case sensitive
# function search_dir(dir, term)
#   command = Cmd(`grep -r $term $dir`; ignorestatus()
"""
Download and search a repo, convenience function.

    search_repo(repo, terms::Array{AbstractString}; dir_path=".")
"""
function search_repo(repo, terms::Array; dir_path=".")
    results = Dict()
    repo_zip = download_repo(repo, dir_path)
    file_type = readstring(`file $repo_zip`)
    if !contains(file_type, "Zip archive data")
      warn(string(repo, " gave: \n", file_type))
      mv(repo_zip, joinpath(dir_path, "not_zip/", splitdir(repo_zip)[2]))
      return results
    end
    repo_dir = try
      unzip(repo_zip, dir_path)
    catch x
      warn(x)
      # rm(repo_zip)
      return results
    end
    for term in terms
        results[term] = try
          length(search_dir(repo_dir, term)) # grep may return a weird error code
        catch x
          warn(x)
          0
        end
    end
    rm(repo_dir; recursive=true)
    rm(repo_zip)
    return results
end

"""Checks to see if a zip file is valid. True if it is valid, false if not."""
function valid_zip(zip_pth)
  error_msg = "zip error: Zip file structure invalid"
  s = readstring(ignorestatus(`zip -T $zip_pth`))
  !contains(s, error_msg)
end

if !check_zip(file)
  download_repo

end
