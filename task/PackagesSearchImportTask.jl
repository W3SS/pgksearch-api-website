module PackagesSearchImportTask

using Genie, SearchLight, GitHub, JSON, Memoize, MetadataTools, App, Logger

function description()
  """
  Searches Github for Julia packages and imports them in the DB
  """
end

function run_task!()
  const github_max_results_limit = 1000
  page_count = 1
  items_count = 0

  while items_count < github_max_results_limit
    items = search_packages(page_count, items_count)

    for result in items
      items_count += 1
      package = Package(name = result["name"], url = result["git_url"])
      try
        existing_package = SearchLight.find_one_by(Package, :url, result["git_url"])
        if isnull(existing_package)
          SearchLight.save!!(package)
        elseif ! isnull(existing_package) && ! haskey(official_packages(), result["name"])
          SearchLight.save!!(existing_package |> Base.get)
        end
      catch ex
        Logger.log(ex |> string, :debug)
      end
    end
    page_count += 1

    sleep(6) #TODO: fix this to use auth requests
  end

end

function search_packages(page::Int, items_count::Int)
  const search_url = "https://api.github.com/search/repositories?q=.jl+language:julia+in:name&sort=stars&order=desc&page=$page"

  response = GitHub.gh_get(search_url, auth = App.GITHUB_AUTH)
  results = ( mapreduce(x -> string(Char(x)), *, response.data) |> JSON.parse )
  items = results["items"]
  total_count = results["total_count"]

  return items
end

@memoize function official_packages()
  MetadataTools.get_all_pkg()
end

end
