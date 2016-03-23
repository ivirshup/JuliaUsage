module SearchRepos
using Requests

export download_repo, unzip, search_dir, search_repo, repo_pths, valid_zip

if OS_NAME == :Linux
  _XARGS = "xargs"
elseif OS_NAME == :Darwin
  _XARGS = "gxargs"
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
    # println("starting to write")
    t0 = time()
    ti = t0
    while !eof(s)
        write(f, readavailable(s))
        dt = time() - ti
        ti = time()
        if time() - t0 > 10
          close(f)
          if counter > 3
            print_with_color(:red, "$(repo) download failed")
            throw("Bad joojoo")
            return out_path
          else
            print_with_color(:red, "$(repo) download restarting. Attempt #$(counter).")
            return download_repo(repo, out_path, counter)
          end
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
search_dir(dir, term) = readlines(ignorestatus(`grep -r $term $dir`)) # case sensitiv
#
"""Searches Julia files in directory for usage of a term, eliminating some false positives."""
function term_usage(dir, term)
  file_selector = `find $(dir) -name "*.jl"` #& `find $(dir) -name REQUIRE`
  search_term = "$(term)\\W|$(term)\$"
  search_cmd = ignorestatus(`$(_XARGS) -rd "\\n" egrep $(search_term)`)
  readlines(ignorestatus(pipeline(file_selector, search_cmd)))
end

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
  b = !contains(s, error_msg)
  b::Bool
end
bad_zips(zips::Array) = convert(Array{Bool}, pmap(x->!valid_zip(x), zips))

function fix_zip(z)
  if !SearchRepos.valid_zip(z)
    println(z)
    # url = (df[:url][df[:path] .== z])[1]
    repo_name = (df[:repo_names][df[:path] .==z])[1]
    # run(`curl -o $z -L $url`)
    println(SearchRepos.download_repo(repo_name, z))
    return true
  else
    return false
  end
end

"""Filters files by type"""
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

end
