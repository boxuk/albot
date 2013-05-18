#!/usr/bin/env coffee

Program = require 'commander'
GitHubApi = require "github"
Async = require 'async'

github = new GitHubApi {
  version: "3.0.0",
 timeout: 5000
}

github.authenticate {
  type: "oauth",
  token: "3765e0a106bafc5066a7f4ae699887751e668819"
}

Program
  .version('0.1.0')

Program
  .command('*')
  .description('List all Pull Requests of the organisation')
  .action () ->
    github.repos.getFromOrg {org: "boxuk", per_page: 100}, (error, repos) ->
      Async.each repos, (repo, callback) ->
        if (repo.name.indexOf('careers-wales') > -1)
          github.pullRequests.getAll {user: "boxuk", repo: repo.name}, (error, prs) ->
            if (error)
              callback(error)
            else
              Async.each prs,
                Async.apply (pr, cb) ->
                  github.pullRequests.get {user: "boxuk", repo: repo.name, number: pr.number}, (error, details) ->
                    status = if details.mergeable then '\u001b[36m✓\u001b[0m' else '\u001b[31m✘\u001b[0m'
                    console.log "#{status} #{details.title} - #{repo.name}"
                    cb(error)
      , (err) ->
        console.log "An error occured #{JSON.stringify(err)}"

Program.parse process.argv
