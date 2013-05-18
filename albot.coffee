#!/usr/bin/env coffee

Program = require 'commander'
GitHubApi = require "github"
Async = require 'async'
Nconf = require 'nconf'

Program
  .version('0.1.0')

Program
  .command('prs')
  .description('List all Pull Requests of the organisation')
  .action () =>
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
                    status = if details.mergeable then '\u001b[36m✓\u001b[0m' else '\u001b[31m✘\u001b[0m'
                    console.log "#{status} #{details.title} - #{repo.name}"
                    cb(error)
      , (err) ->
        console.log "An error occured #{JSON.stringify(err)}"

Nconf.argv().env().file({file: '.albot.json'})

@github = new GitHubApi { version: "3.0.0" }
@github.authenticate { type: "oauth", token: Nconf.get("github_token") }

@org = Nconf.get("organisation")

Program.parse process.argv
