Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Async = require 'async'
_ = require('underscore')._

GitHubApi = require 'github'

Utils = require './utils'

@github = new GitHubApi { version: "3.0.0" }
@github.authenticate { type: "oauth", token: Nconf.get("github_token") }

@org = Nconf.get("organisation")

pulls = () =>
  @github.repos.getFromOrg {org: @org, per_page: 100}, (error, repos) =>
    Async.each repos, (repo, callback) =>
      if (repo.name.indexOf(Nconf.get("filter")) > -1)
        @github.pullRequests.getAll {user: @org, repo: repo.name}, (error, prs) =>
          if (error)
            callback(error)
          else
            Async.each prs,
              Async.apply (pr, cb) =>
                @github.pullRequests.get {user: @org, repo: repo.name, number: pr.number}, (error, details) ->
                  Utils.display(details.mergeable, details.title, details.html_url, repo.name, details.comments)
                  cb(error)
    , (err) ->
      console.log "An error occured #{JSON.stringify(err)}"

module.exports = {
  pulls: {
    description: "List all Pull Requests of the organisation",
    action: pulls
  }
}
