# Download repos and checks that it was done correctly
####
# Steps
# 1 Get list of repos to download (from json)
# 2 Make those unique by id
# 3 Download zips
# 4 Identify non-zip files I've downloaded -> remove from list of zips + rename
# 5 Idenify invalid zips I've downloaded -> If there are any (3) with this list
# 6 Associate unziped dir name with all zipped files.
# 7 Write out dataframe?
include("repo_setup.jl")
using DataFrames
import DataOps
import RepoMgmt

repo_json = joinpath(pth, "data", "julia_repos_test.json")
@everywhere data_pth = joinpath(pth, "data/repos/")

# Collect + setup data
df = RepoMgmt.json2df(RepoMgmt.read_json(repo_json))
for s in [:created_at, :pushed_at, :updated_at] # Seeting these columns to DateTime values
  df[s] = map(RepoMgmt.todt, df[s])
end
df = RepoMgmt.reduce_dates(df, :id; min_creation=true)
delete!(df, :id_1) # TODO: check if this happens everytime. If so, just delete in function
df[:zipfile] = pmap(x->DataOps.download_repo(x, data_pth), df[:full_name])
# df[:zipfile] = pmap(x->DataOps.repo_pths(x, data_pth)[2], df[:full_name])
# Filter for failing urls and redownload incomplete files.
check_again = true
counter = 0 # counter for giving up on stuborn files
while check_again
  not_zips = !convert(Array{Bool}, pmap(DataOps.iszip, df[:zipfile])) # Bad urls
  println("not_zips: $not_zips")
  if any(not_zips)
    # show(df[not_zips])
    pmap(DataOps.fixext, df[:zipfile][not_zips])
    df = df[!not_zips,:]
    show(df)
  end
  bad_zips = DataOps.bad_zips(df[:zipfile]) # Incomplete .zip files # TODO, make this part of initial download
  println("bad_zips: $bad_zips")
  if any(bad_zips) && counter < 4
    pmap(x->DataOps.download_repo(x, data_pth), df[:full_name][bad_zips])
    counter += 1
  else
    for pain_file in df[:zipfile][bad_zips]
      if isfile(pain_file)
        rm(pain_file)
      end
    end
    df = df[!bad_zips, :]
    check_again = false
  end
end

# Get names of zip files.
df[:repo_dir] = pmap(DataOps.unziped_name, df[:zipfile])

# I should now probably check to see if I get repeats here before actually doing much with it.
let zips = df[:zipfile]
  df = RepoMgmt.reduce_dates(df, :repo_dir)
  zips = setdiff(zips, RepoMgmt, :zipfile)
  for repeat in zips
    rm(repeat)
  end
end
