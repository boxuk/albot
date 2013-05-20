Configuration = require './configuration'

Async = require 'async'
_ = require('underscore')._

GitHubApi = require 'github'

Utils = require './utils'

@github = new GitHubApi { version: "3.0.0", debug: Configuration.get("github").debug }
@github.authenticate { type: "oauth", token: Configuration.get("github").token }

@org = Configuration.get("github").organisation
@repo_filter = Configuration.get("github").repo_filter

pulls = (fallback) =>
  @github.repos.getFromOrg {org: @org, per_page: 100}, (error, repos) =>
    Async.each repos, (repo, callback) =>
      if (repo.name.indexOf(@repo_filter) > -1)
        @github.pullRequests.getAll {user: @org, repo: repo.name}, (error, prs) =>
          if (error)
            callback(error)
          else
            Async.each prs,
              Async.apply (pr, cb) =>
                @github.pullRequests.get {user: @org, repo: repo.name, number: pr.number}, (error, details) ->
                  Utils.printWithFallback(fallback)(details.title, details.html_url, repo.name, details.comments + " comments", details.mergeable)
                  cb(error)
    , (err) ->
      console.log "An error occured #{JSON.stringify(err)}"

help = (fallback) ->
  for key, value of list
    Utils.printWithFallback(fallback)(key, null, null, value.description)

list = {
  pulls: {
    name: "Pull Requests"
    description: "List all Pull Requests of the organisation",
    action: pulls
  },
  help: {
    name: "Help"
    description: "Display a list of available commands",
    action: help
  }
}

module.exports = list
