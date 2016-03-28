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
			{"full_name": 1, "name":1, "owner.login": 1, "created_at":1, "pushed_at": 1, "updated_at": 1, "size":1}
						         ).toArray()
		for (var result in results) {
			printjson(results[result])
			// data.push(results[result])
		}
	}
	return data
}

get_julia_repos(julia_repos)
