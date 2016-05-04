using FactCheck
push!(LOAD_PATH, joinpath(dirname(@__FILE__), ".."))
import RepoMgmt
import DataOps

facts("Downloading/ searching repos") do
  data_pth = mktempdir()
  repo_name = "JuliaLang/Example.jl"
  url_pth, zip_pth = DataOps.repo_pths(repo_name, data_pth)
  @fact url_pth --> "https://github.com/JuliaLang/Example.jl/zipball/master/"

  context("'The Basics'") do
    DataOps.download_repo(repo_name, zip_pth)
    @fact isfile(zip_pth) --> true
    @fact DataOps.valid_zip(zip_pth) --> true # TODO figure this out
    repo_dir = DataOps.unzip(zip_pth, data_pth)
    @fact DataOps.unziped_name(zip_pth) --> repo_dir
    @fact length(DataOps.module_usage(repo_dir, "Example")) --> 1
    @fact DataOps.term_used(DataOps.module_usage(repo_dir, "Example")) --> "Example"
    rm(repo_dir; recursive=true)
  end

  context("Bad zips! No!") do
    bad_pth = string(zip_pth[1:end-4], "_bad.zip")
    bs = read(zip_pth)
    open(bad_pth, "w") do bad_zip
      write(bad_zip, bs[1:end-3]) # Writing a bad zip file
    end
    @fact DataOps.valid_zip(bad_pth) --> false
    run(ignorestatus(`zip -T $bad_pth`))
    rm(bad_pth)
  end

  # context("Big zip") do # This zip is large enough I typically can't download it.
  #   url = "https://github.com/varnerlab/NickHorvath_Repository"
  #
  # end
  context("Not a zip") do
    bad_repo = "JuliaLang/Exmple"
    bad_pth = DataOps.download_repo(bad_repo, data_pth)
    @fact DataOps.iszip(bad_pth) --> false
    fixed_ext = DataOps.fixext(bad_pth)
    @fact fixed_ext --> string(splitext(bad_pth)[1], ".html")
    rm(fixed_ext)
    good_pth = DataOps.download_repo(repo_name, data_pth)
    @fact DataOps.iszip(good_pth) --> true
  end
end

# Tests which should more or less replicate script behaviour.
facts("Functional!") do
  sample_entry = """{
  	"id" : 6360817,
  	"name" : "Example.jl",
  	"full_name" : "JuliaLang/Example.jl",
  	"owner" : {
  		"login" : "JuliaLang"
  	},
  	"created_at" : "2012-10-23T22:06:51Z",
  	"updated_at" : "2013-02-14T20:12:20Z",
  	"pushed_at" : "2012-11-22T15:32:39Z",
  	"size" : 180
  }
  {
  	"id" : 6360817,
  	"name" : "Example.jl",
  	"full_name" : "JuliaLang/Example.jl",
  	"owner" : {
  		"login" : "JuliaLang"
  	},
  	"created_at" : "2012-10-23T22:06:51Z",
  	"updated_at" : "2015-12-10T16:34:21Z",
  	"pushed_at" : "2015-10-17T05:21:06Z",
  	"size" : 311
  }"""
  ex_pth, ex_io = mktemp()
  write(ex_io, sample_entry)
  close(ex_io)

  data_pth = mktempdir()

  # Setting up df
  df = RepoMgmt.json2df(RepoMgmt.read_json(ex_pth))
  for s in [:created_at, :pushed_at, :updated_at] # Seeting these columns to DateTime values
    df[s] = map(RepoMgmt.todt, df[s])
  end
  max_pushed = maximum(df[:pushed_at])
  min_created = minimum(df[:created_at])
  df = RepoMgmt.reduce_dates(df, :id; min_creation=true)
  # TODO generalize these tests beyond the one sample example.
  @fact df[1, :pushed_at] --> max_pushed
  @fact df[1, :created_at] --> min_created
  df[:zipfile] = fill("", size(df)[1])
  for (idx, repo) in enumerate(df[:full_name])
    df[idx, :zipfile] = DataOps.download_repo(repo, data_pth)
    if DataOps.iszip(df[idx, :zipfile])
      while !DataOps.valid_zip(df[idx, :zipfile])
        df[idx, :zipfile] = DataOps.download_repo(repo, data_pth)
      end
    else
      df[idx, :zipfile] = DataOps.fixext(df[idx, :zipfile])
      warn("Repo $(df[idx, :full_name]) giving weird file. \n $(df[idx, :zipfile])")
    end
  end
  @fact all(DataOps.valid_zip, df[:zipfile]) --> true
  df[:repo_dir] = map(x->DataOps.unzip(x, data_pth), df[:zipfile])
  @fact isdir(df[1,:repo_dir]) --> true
  @fact length(DataOps.module_usage(df[1,:repo_dir], "Example")) --> 1
end
