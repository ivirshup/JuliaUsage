using DataStructures
using DataFrames
using GitHub
import GitHub.chopz

myauth = GitHub.authenticate(ENV["GITHUB_AUTH"])

function search_code(query; options...)
    GitHub.gh_get_paged_json("/search/code?q=$(query)" ; options...)
end

function search_repos(term, users, all_repos=[])
    for user in users # Probably put in try catch
        println("Starting: $(user)")
        user_results = try
            search_code("$(term)+in:file+language:Julia+user:$(user)"; auth=myauth)
        catch x
            if isa(x, ErrorException)
                println(x)
                if contains(x.msg,"API rate limit") # Probably make optional
                    println("Hit rate limit. Waiting for a minute")
                    sleep(60)
                    push!(users, user)
                end
                continue
            else
                println(user)
                println(typeof(x))
                warn(x)
                continue
            end
        end
#         push!(repos, user_results)
        if isa(user_results[1], Array)
            query_hits = vcat(map(x->x["items"], user_results[1])...)
        elseif user_results[1]["total_count"] > 0
            query_hits = user_results[1]["items"]
        else
            continue
        end
        user_repos = unique(map(x->x["repository"]["full_name"], query_hits))
        append!(all_repos, user_repos)
    end
    all_repos
end


julia_repos = let df=readtable("../data/julia_repos.csv")
    df[:repos] = map(x->x[30:end], df[:_url_])
    Array{AbstractString}(df[:repos])
end

unique_users = unique(map(x->split(x, "/")[1], julia_repos))

fd_usage = []
search_repos("ForwardDiff", unique_users, fd_usage)
serialize(open("../data/fd_usage.jld", "w"), fd_usage)
