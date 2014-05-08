Configuration = require './configuration'
Aliases = Configuration.Nconf.get('aliases')
Changelog = Configuration.Nconf.get('changelog')

_ = require('underscore')._
_.str = require 'underscore.string'
_.mixin _.str.exports()

Github = Configuration.Github
Async = require 'async'
Moment = require 'moment'

Utils = require './utils'
GhHelpers = require './gh_helpers'

changelog = (fallback, repo, keyword, filter, period, save) ->
  repo = Aliases[repo] || repo
  org = Github.Org

  # First we verify if the first argument is an URL
  match = GhHelpers.githubPRUrlMatching repo
  if (match?)
    org = match[0].org
    repo = match[0].repo
    filter = match[0].number
    keyword = 'pr'

  if (keyword == 'pr')
    forPullRequests(fallback, org, repo, filter, period, save)

  if (keyword == 'since')
    forSince(fallback, org, repo, filter, period, save)

  if (keyword == 'between')
    forBetween(fallback, org, repo, filter, period, save)

forPullRequests = (fallback, org, repo, filter, period, save) ->
  Github.Api.pullRequests.getCommits {
    user: org
    repo: repo
    number: filter
  }, (error, commits) ->
    if (error?)
      Utils.fallback_printError(fallback, error)
    else
      display(fallback, org, repo, commits, period)

forSince = (fallback, org, repo, filter, period, save) ->
  Github.Api.repos.getCommits {
    user: org
    repo: repo
    since: Moment().subtract(period, filter).format()
  }, (error, commits) ->
    if (error?)
      Utils.fallback_printError(fallback, error)
    else
      display(fallback, org, repo, commits, save)

forBetween = (fallback, org, repo, filter, period, save) ->
  if (_.str.include filter, "...")
    first = _.first filter.split("...")
    last = _.last filter.split("...")
    save = period
  else if (_.str.include filter, "..")
    first = _.first filter.split("..")
    last = _.last filter.split("..")
    save = period
  else
    first = filter
    last = period

  Github.Api.repos.compareCommits {
    user: org
    repo: repo
    base: first
    head: last
  }, (error, diff) ->
    if (error?)
      Utils.fallback_printError(fallback, error)
    else
      display(fallback, org, repo, diff.commits, save)

display = (fallback, org, repo, commits, save) ->
  Async.map commits, (commit, callback) ->
    
    if (commit.committer.gravatar_id?)
      avatarId = commit.committer.gravatar_id
    else
      avatarId = ''

    Github.Api.statuses.get {
      user: org,
      repo: repo,
      sha: commit.sha
    }, (error, statuses) ->
      callback null, {
        title: commit.commit.message
        url: "https://github.com/#{org}/#{repo}/commit/#{commit.sha}"
        comments: Moment(commit.commit.committer.date).fromNow()
        avatar: avatarId
        order: commit.commit.committer.date
        status: GhHelpers.buildStatus(statuses)
      }
  , (err, list) ->
    list = _.filter list, (object) ->
      not object.title.match(new RegExp '^Merge')

    if (save == "save")
      saving(fallback, list)
    else
      Utils.fallback_printList fallback, list

saving = (fallback, list) ->
  gist list, (error, url) ->
    if (error?)
      Utils.fallback_printError(fallback, error)
    else
      Utils.fallback_print(fallback) {
        title: "View the changelog"
        url: url
        comments: url
        status: true
      }

gist = (list, callback) ->
  data = _.reduce list, (memo, o) ->
    memo += '- '
    memo += o.title
    memo += '\n'
  , ""

  Github.Api.gists.edit { id: Changelog.gistId, files: {"history.md": { content: data } }}, (err, gist) ->
    if (err?) then callback(err) else callback(null, gist.html_url + "/" + gist.history[0].version)

module.exports = {
  name: "Changelog",
  description: "-project- [ | -alias-] -pr- -number-
 | -since- -number- -period- | -between- -tag-range-
 [save] List changelog for a given PR, period, range ",
  action: changelog
}
