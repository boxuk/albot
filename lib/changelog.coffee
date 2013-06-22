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

changelog = (fallback, repo, keyword, filter, period, save) ->
  repo = Deploy.aliases[repo] || repo

  if (keyword == 'pr')
    Github.Api.pullRequests.getCommits {
      user: Github.Org
      repo: repo
      number: filter
    }, (error, commits) ->
      if (error?)
        Utils.fallback_printError(fallback, error)
      else
        display(fallback, commits, period)        

  if (keyword == 'since')
    Github.Api.repos.getCommits {
      user: Github.Org
      repo: repo
      since: Moment().subtract(period, filter).format()
    }, (error, commits) ->
      if (error?)
        Utils.fallback_printError(fallback, error)
      else
        display(fallback, commits, save)

  if (keyword == 'between')
    if (_.str.include filter, "...")
      first = _.first filter.split("...")
      last = _.last filter.split("...")
    else
      first = _.first filter.split("..")
      last = _.last filter.split("..")      

    Github.Api.repos.compareCommits {
      user: Github.Org
      repo: repo
      base: first
      head: last
    }, (error, diff) ->
      if (error?)
        Utils.fallback_printError(fallback, error)
      else
        display(fallback, diff.commits, period)        

display = (fallback, commits, save) ->
  list = _.map commits, (commit) -> {
    title: commit.commit.message
    comments: Moment(commit.commit.committer.date).fromNow()
    order: commit.commit.committer.date
  }
  list = _.filter list, (object) ->
    not object.title.match(new RegExp '^Merge')

  if (save == "save")
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
  else
    Utils.fallback_printList fallback, list

gist = (list, callback) ->
  data = _.reduce list, (memo, o) ->
    memo += '- ' + o.title + ' - *' + o.comments + '*' + '\n'
  , ""

  Github.Api.gists.edit { id: Changelog.gistId, files: {"history.md": { content: data } }}, (err, gist) ->
    if (err?) then callback(err) else callback(null, gist.html_url)                 

module.exports = {
	name: "Changelog"
	description: "-project- | -alias- [-pr- [-number-] 
  | -since- [-number-] [-period-] | -between- [-tag-range-]
  ] [-save-] List changelog for a given PR, period, range ",
	action: changelog
}