load("/Users/isaac/GoogleDrive/Work/Julia/JuliaUsage/data/julia_repos2.js")
function name_from_url(repo_url) {
	l = repo_url.length
	return repo_url.substring(29, l)
}

function get_julia_repos(julia_repos) {
	var data = []
	for (var repo in julia_repos) {
		repo_fields = name_from_url(julia_repos[repo]).split("/")
		var results = db.repos.find(
			{"name": repo_fields[1],
			 "owner.login": repo_fields[0]},
			{ "_id": 0,// What I'm including (basically, don't want a ton of urls)
				"id": 1,
			  "owner.login": 1,								// Owner info
				"owner.id": 1,
				"owner.type": 1,
				"owner.site_admin": 1,
				"name": 1,											// Name
				"full_name": 1,
				"description": 1,
				"private": 1,										// Metadata (maybe important?)
				"fork": 1,
				"forks_count": 1,
				"stargazers_count": 1,
				"watchers_count": 1,
				"size": 1,
				"open_issues_count": 1,
				"has_issues": 1,
				"has_wiki": 1,
				"has_pages": 1,
				"has_downloads": 1,
				"created_at": 1, 								// Dates
				"pushed_at": 1,
				"updated_at": 1,
			}).toArray()
		for (var result in results) {
			printjson(results[result])
			// data.push(results[result])
		}
	}
	return data
}

get_julia_repos(julia_repos)
