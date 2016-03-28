# module filter_repos

export group_by_dates, read_json, json2df, todt

using DataFrames
using JSON

# julia_repos = let df=readtable("../data/julia_repos.csv")
#     df[:repos] = map(x->x[30:end], df[:_url_])
#     Array{AbstractString}(df[:repos])
# end

# Data was retrieved by running julia_repos2.js on the GHTorrent mongo server.
function clean_file()
  # run this cat julia_repos2.json | sed -E "s/ObjectId\((.*)\)/\1/" > julia_repos2_edited.json
end

"""Reads in json saved from Mongo"""
function read_json(file_path)
  output = []
  println(typeof(output))
  f = open(file_path)
  while !eof(f)
    push!(output, JSON.parse(f))
  end
  close(f)
  filter!(x->x!=nothing, output)
end

"""Reads json from Mongo into a dataframe"""
function json2df(raw_metadata)
  df = DataFrame()
  for k in keys(raw_metadata[1])
    df[symbol(k)] = map(x->x[k], raw_metadata)
  end
  df
end

"""Given a GitHub formatted date time, convert it to more useful datatime"""
function todt(entry::AbstractString)
  if entry[end] == 'Z'
    entry = entry[1:end-1]
  end
  DateTime(entry)
end

function group_by_dates(df)
  by(df, :id) do subdf
    ma = maximum(subdf[:pushed_at]) # Find latest date pushed
    outdf = subdf[subdf[:pushed_at] .== ma ,:][1,:] # Return entry with latest date pushed
    outdf[:created_at] = minimum(subdf[:created_at])
    outdf
  end
end

function main()
  raw_metadata = read_json("/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/julia_repos3.json")
  df = json2df(raw_metadata)
  df[:created_at] = map(todt, df[:created_at])
  df[:pushed_at] = map(todt, df[:pushed_at])
  df[:updated_at] = map(todt, df[:updated_at])
  group_by_dates(df) # Make unique by repo names, find max pushed_at, and min created_at
end
main()
# end/
