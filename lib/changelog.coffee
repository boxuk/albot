Configuration = require './configuration'
Deploy = Configuration.Nconf.get('deploy')
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
  repo = Deploy.aliases[repo] || repo
  org = Github.Org

  # First we verify if the first argument is an URL
  match = GhHelpers.githubPRUrlMatching repo
  if (match?)
    org = match.org
    repo = match.repo
    keyword = 'pr'
    filter = match.number

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
  else
    first = _.first filter.split("..")
    last = _.last filter.split("..")

  Github.Api.repos.compareCommits {
    user: org
    repo: repo
    base: first
    head: last
  }, (error, diff) ->
    if (error?)
      Utils.fallback_printError(fallback, error)
    else
      display(fallback, org, repo, diff.commits, period)

display = (fallback, org, repo, commits, save) ->
  Async.map commits, (commit, callback) ->
    Github.Api.statuses.get {
      user: org,
      repo: repo,
      sha: commit.sha
    }, (error, statuses) ->
      callback error, {
        title: commit.commit.message
        url: "https://github.com/#{org}/#{repo}/commit/#{commit.sha}"
        comments: Moment(commit.commit.committer.date).fromNow()
        avatar: commit.committer.gravatar_id
        order: commit.commit.committer.date
        status: GhHelpers.buildStatus(statuses)
      }
  , (err, list) ->
    if (err?)
      Utils.fallback_printError(fallback, err)
    else
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
    memo += '- ' + o.title + ' - *' + o.comments + '*' + '\n'
  , ""

  Github.Api.gists.edit { id: Changelog.gistId, files: {"history.md": { content: data } }}, (err, gist) ->
    if (err?) then callback(err) else callback(null, gist.html_url + "/" + gist.history[0].version)

module.exports = {
  name: "Changelog",
  description: "-project- [ | -alias-] -pr- -number-
 | -since- -number- -period- | -between- -tag-range-
 [\"save\"] List changelog for a given PR, period, range ",
  action: changelog
}
