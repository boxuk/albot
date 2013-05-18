#!/usr/bin/env coffee

Program = require 'commander'
Nconf = require 'nconf'
Async = require 'async'
_ = require('underscore')._

GitHubApi = require "github"
HipchatApi = require 'hipchat'

Program.version('0.1.0')

Program
  .command('server')
  .action () =>
    @rooms.history "albot", (error, lines) =>
      if (error) then console.log(error)
      else if(lines)
        @cache = _.map(lines.messages, (m) -> JSON.stringify(m))

    setInterval () =>
      console.log("tick" + JSON.stringify(@cache))
      @rooms.history "albot", (error, lines) =>
        if (error) then console.log(error)
        else if (lines)
          Async.each lines.messages, (line, cb) =>
            if (not _.contains(@cache, JSON.stringify(line)))
              if (line.from.name isnt "Bot")
                console.log("new line" + JSON.stringify(line))
                @rooms.message("albot", "Bot", line.message)
            cb(null)
          , (err) =>
            console.log("Update cache")
            @cache = _.map(lines.messages, (m) -> JSON.stringify(m))
    , 5000

Program
  .command('deploy')
Program
  .command('diff')
Program
  .command('version')
Program
  .command('tag')
Program
  .command('retest')
Program
  .command('shipit')

display = (details, repo) =>
  statusCmd = if details.mergeable then '\u001b[36m✓\u001b[0m' else '\u001b[31m✘\u001b[0m'
  status = if details.mergeable then "✓" else "✘"
  statusColor = if details.mergeable then "green" else "red"

  console.log "#{statusCmd} #{details.title} - #{repo.name}"
  @rooms.message("albot", "bot", "#{status} <i>#{details.title}</i>: <strong>#{repo.name}</strong>", {message_format: "html", color: statusColor})

prs = () =>
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
                  display(details, repo)
                  cb(error)
    , (err) ->
      console.log "An error occured #{JSON.stringify(err)}"

Program
  .command('prs')
  .description('List all Pull Requests of the organisation')
  .action prs

Nconf.argv().env().file({file: '.albot.json'})

@github = new GitHubApi { version: "3.0.0" }
@github.authenticate { type: "oauth", token: Nconf.get("github_token") }

@rooms = new HipchatApi(Nconf.get("hipchat_token")).Rooms

@org = Nconf.get("organisation")

Program.parse process.argv
