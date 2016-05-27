#TODO rename
"""
Module for downloading packages outside of the package ecosystem.

Originally for doing large scale static analysis of the Julia ecosystem. Basically a set of tools for downloading zips of git repositories, and some basic tools for searching their text.
"""
module DataOps
using Requests
using DataStructures

export download_repo, unzip, search_dir, search_repo, repo_pths, valid_zip

_dir = dirname(@__FILE__)
_repo_pth = joinpath(_dir, "data", "repos")
### Zip stuff
if OS_NAME == :Linux
  _XARGS = "xargs"
elseif OS_NAME == :Darwin
  _XARGS = "gxargs"
end

###
### Zip files
###

"""Get all repos (`*.zip` files) at `path`

`repo(path)`
"""
repos(path=repo_pth) = filter(x->contains(x, ".zip"), readdir(path))

"""Given a repo name and directory create url and output path.""" # TODO Does name conversion count as data management?
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

"""Checks to see if a zip file is valid. True if it is valid, false if not."""
function valid_zip(zip_pth)
  error_msg = "zip error:"
  s = readstring(ignorestatus(`zip -T $zip_pth`))
  b = !contains(s, error_msg)
  b::Bool
end
bad_zips(zips::AbstractArray) = convert(Array{Bool}, pmap(x->!valid_zip(x), zips))

"""Identifies if file is a .zip file"""
function iszip(path)
  ftype = readstring(`file $path`)
  return contains(ftype, "Zip archive data")
end

"""Finds out the unziped name of the file without actually expanding it."""
function unziped_name(zip_path)
  zip_dir = splitdir(zip_path)[1]
  repo_dir = chomp(readlines(`zipinfo -1 $zip_path`)[1])
  return joinpath(zip_dir, repo_dir)
end

"""Fixes the extension of passed file.

Pretty specifically for use in the case of downloading zip files from github."""
function fixext(path)
  ftype = readstring(`file $path`)
  file_pth = splitext(path)[1]
  if contains(ftype, "HTML")
    new_name = string(file_pth, ".html")
  elseif contains(ftype, "ASCII")
    new_name = string(file_pth, ".txt")
  else
    throw("Unknown type! \n $(path) \n $(ftype)")
  end
  mv(path, new_name, remove_destination=true)
  new_name
end

"""Doesn't actually work if called in module"""
function fix_zip(z)
  if !valid_zip(z)
    println(z)
    repo_name = (df[:repo_names][df[:path] .==z])[1]
    println(download_repo(repo_name, z))
    return true
  else
    return false
  end
end

"""
Downloads zip of repo, returns path of file.

    download_repo("JuliaLang/julia", "out/")
"""
function download_repo(repo, out_path, counter=0)
    counter += 1
    url, out_path = repo_pths(repo, out_path)
    s =Requests.get_streaming(url)
    println(url)
    f = open(out_path, "w")
    t0 = time()
    ti = t0
    while !eof(s) # TODO figure out what I'm doing with all this timing
        write(f, readavailable(s))
        dt = time() - ti # Time between things
        ti = time()
        if time() - t0 > 10
          close(f)
          if counter > 3
            print_with_color(:red, "$(repo) download failed.\n")
            warn("Bad joojoo")
            return out_path
          else
            print_with_color(:red, "$(repo) download restarting. Attempt #$(counter).")
            return download_repo(repo, out_path, counter)
          end
        end
    end
    flush(f)
    close(f)
    # println("done writing")
    return out_path
end

"""Filters files by type""" # TODO is this still relevant? It must be, right? For creating a repo from scratch. I think this may be solved by splitting it up. Now can be replicated by iszip, fixext, and just valid_zip
function filter_zip(zip_pth)
  is_fine = true
  f = zip_pth
  ftype = readstring(`file $f`)
  if !contains(ftype, "Zip archive data")
    is_fine = false
    file_name = splitext(f)[1]
    if contains(ftype, "HTML")
      mv(f, string(file_name, ".html"), remove_destination=true)
    elseif contains(ftype, "ASCII")
      mv(f, string(file_name, ".txt"), remove_destination=true)
    else
      println(f)
      println(ftype)
    end
  elseif !valid_zip(f)
    is_fine = false
    print_with_color(:red, "Not valid zip: $(f).")
  end
  return is_fine
end

###
### Search stuff
###

search_dir(dir, term) = readlines(ignorestatus(`grep -r $term $dir`))

"""Searches Julia files in directory for usage of a term, eliminating some false positives."""
function term_usage(dir, term)
  file_selector = `find $(dir) -name "*.jl"` #& `find $(dir) -name REQUIRE`
  search_term = "[^#]($(term)\\W|$(term)\$)"
  search_cmd = ignorestatus(`$(_XARGS) -rd "\\n" egrep $(search_term)`)
  readlines(ignorestatus(pipeline(file_selector, search_cmd)))
end

"""Searches for if term is used as a module (i.e. `using`, `import`)"""
function module_usage(dir, term)
  file_selector = `find $(dir) \( -name "*.jl" -o -name "*.ipynb" \) -size -8000` #& `find $(dir) -name REQUIRE`
  search_term = "^\\s*(using|import).*[^\\w]($(term)\\W.{0,200}|$(term)\$)"
  search_cmd = ignorestatus(`$(_XARGS) -rd "\\n" egrep $(search_term)`)
  readlines(ignorestatus(pipeline(file_selector, search_cmd)))
end

function term_used(string)
    m = match(r"(using|import).*[^\w](\w+)\W.{0,200}", string)
    c = m.captures[2:end]
end

function term_usage(dir, commands::Union{Tuple{Vararg{Cmd}}, Array{Cmd}})
  readlines(ignorestatus(pipeline(commands)))
end

function get_repo_instances(repo, terms::Array, repo_pth=_repo_pth)
  d = Dict()
  d[repo] = Dict()
  rd_name = try
    unzip(repo, repo_pth)
  catch x
    warn(x)
    println(repo)
    return d
  end
    # rd_name = SearchRepos.unzip(joinpath(repo_pth, r), repo_pth)
  println(rd_name)
  println(joinpath(repo_pth, rd_name))
  for t in terms
    d[repo][t] = module_usage(joinpath(repo_pth, rd_name), t)
  end
  rm(rd_name; recursive=true)
  d
end

"""
Download and search a repo, convenience function.

    search_repo(repo, terms::Array{AbstractString}; dir_path=".")
"""
function search_repo(repo, terms::Array; dir_path=".")
    results = Dict()
    repo_zip = download_repo(repo, dir_path)
    file_type = readstring(`file $repo_zip`) # TODO remove this
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

end
