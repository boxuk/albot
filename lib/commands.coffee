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

pulls = (fallback) =>
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
                      status = statuses[0]
                      mergeable = if status? and status.state is 'pending' then undefined else status.state is 'success'
                      Utils.printWithFallback(fallback)(details.title, details.html_url, repo.name, details.comments + " comments", mergeable, details.user.gravatar_id)
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
    description: "List all Pull Requests of the organisation",
    action: pulls,
    isRepoInFilters: isRepoInFilters
  },
  help: {
    name: "Help"
    description: "Display a list of available commands",
    action: help
  }
}

module.exports = list
