Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Async = require 'async'
_ = require('underscore')._

GitHubApi = require 'github'

Utils = require './utils'

@github = new GitHubApi { version: "3.0.0" }
@github.authenticate { type: "oauth", token: Nconf.get("github").token }

@org = Nconf.get("github").organisation
@repo_filter = Nconf.get("github").repo_filter

pulls = () =>
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
                  Utils.print(details.title, details.html_url, repo.name, details.comments + " comments", details.mergeable)
                  cb(error)
    , (err) ->
      console.log "An error occured #{JSON.stringify(err)}"

tag = (repo) =>
  # Use Async here
  @github.repos.getTags {user: "athieriot", repo: repo}, (error, tags) =>
    current = tags[0]
    next = if current then current.name.parseInt + 1 else 1
    @github.repos.getBranches {user: "athieriot", repo: repo}, (error, branches) =>
      if (not error)
        master = _.find(branches, (b) -> b.name is "master")
        @github.gitdata.createTag {
          user: "athieriot", repo: repo,
          message: next.toString, object: master.commit.sha, tag: next.toString, type: "commit",
          tagger: { name: "Aurélien Thieriot", email: "a.thieriot@gmail.com", date: new Date().getTime() }
        }, (error, tag) =>
          if (not error)
            @github.gitdata.createReference {user: "athieriot", repo: repo, ref: "refs/tags/#{tag.tag}", sha: tag.sha }, (error, tag) =>
              if (not error)
                Utils.print(next, null, repo, tag.object.sha)

help = () ->
  for key, value of list
    Utils.print(key, null, null, value.description)

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
