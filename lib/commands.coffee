Configuration = require './configuration'

Async = require 'async'
_ = require('underscore')._

GitHubApi = require 'github'

Utils = require './utils'

@github = new GitHubApi { version: "3.0.0", debug: Configuration.get("github").debug }
@github.authenticate { type: "oauth", token: Configuration.get("github").token }

@org = Configuration.get("github").organisation

isRepoInFilters = (name) ->
  repo_filters = Configuration.get("github").repo_filters
  _.some repo_filters, (filter) ->
    name.indexOf(filter) > -1

shouldBeDisplayed = (keyword, filter, title) ->
  if (not filter?) then return true

  term = filter.toLowerCase()
  query = title.toLowerCase()
  if (keyword is 'without' and query.indexOf(term) > -1) then return false
  else if (keyword is 'with' and query.indexOf(term) == -1) then return false
  else return true

buildStatus = (statuses) ->
  status = statuses[0] if statuses?
  if status? and status.state? and status.state is 'pending' then undefined else status.state is 'success'

needRebase = (mergeable) ->
  if mergeable then "" else " - *NEED REBASE*"

pulls = (fallback, keyword, filter) =>
  @github.repos.getFromOrg {org: @org, per_page: 100}, (error, repos) =>
    Async.each repos, (repo, callback) =>
      if (isRepoInFilters(repo.name))
        @github.pullRequests.getAll {user: @org, repo: repo.name}, (error, prs) =>
          if (error)
            callback(error)
          else
            Async.each prs,
              Async.apply (pr, cb) =>
                @github.pullRequests.get {user: @org, repo: repo.name, number: pr.number}, (error, details) =>
                    @github.statuses.get {user: @org, repo: repo.name, sha: details.head.sha}, (error, statuses) ->
                      query = details.title + repo.name + details.user.login
                      if (shouldBeDisplayed(keyword, filter, query))
                        Utils.printWithFallback(fallback)(details.title, details.html_url, repo.name, details.comments + " comments" + needRebase(details.mergeable), buildStatus(statuses), details.user.gravatar_id)
                      cb(error)
    , (err) ->
      console.log "An error occured #{JSON.stringify(err)}"

help = (fallback) ->
  for key, value of list
    Utils.printWithFallback(fallback)(key, null, null, value.description)

# All the commands should have a fallback function or null as first argument
# TODO: See if we can make that cleaner
list = {
  pulls: {
    name: "Pull Requests"
    description: "[without <filter>] List all Pull Requests of the organisation",
    action: pulls,
    isRepoInFilters: isRepoInFilters,
    shouldBeDisplayed: shouldBeDisplayed
  },
  help: {
    name: "Help"
    description: "Display a list of available commands",
    action: help
  }
}

module.exports = list
