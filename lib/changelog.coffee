Configuration = require './configuration'
Deploy = Configuration.Nconf.get('deploy')

_ = require('underscore')._

Github = Configuration.Github
Async = require 'async'
Moment = require 'moment'

Utils = require './utils'

changelog = (fallback, repo, keyword, filter) ->
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
        list = _.map commits, (commit) -> {
          title: commit.commit.message
        }
        Utils.fallback_printList fallback, list, (list) ->
          _.filter list, (object) ->
            not object.title.match(new RegExp '^Merge')

module.exports = {
	name: "Changelog"
	description: "",
	action: changelog
}