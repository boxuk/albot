Configuration = require './configuration'
_ = require('underscore')._
_.str = require 'underscore.string'
_.mixin _.str.exports()

Github = Configuration.Github
Async = require 'async'
Moment = require 'moment'

Utils = require './utils'
GhHelpers = require './gh_helpers'

#TODO: Speeeeeeeeeeed
pulls = (fallback, keyword, filter, extra) ->

  # First we verify if the arguments are URLs
  args = keyword + ' ' + filter + ' ' + extra
  match = GhHelpers.githubPRUrlMatching(args)
  if (match?)
    getInfoPulls match, (error, results) ->
      if (error?)
        Utils.fallback_printError(fallback, error)
      else
        Utils.fallback_printList fallback, results

  else
    getAllRepos keyword, filter, Github.Org, 1, [], (err, list) ->
      if (err?)
        Utils.fallback_printError(fallback, err)
      else
        Utils.fallback_printList fallback,
          list, _.partial(pickLastIfNeeded, keyword, filter)

getInfoPulls = (list, callback) ->
  Async.map list, (match, cb) ->
    getInfoPull match.org, match.repo, match.number, cb
  , callback

getInfoPull = (org, reponame, number, callback) ->
  Github.Api.pullRequests.get {
    user: org,
    repo: reponame,
    number: number
  }, (error, details) =>
    if (error?)
      callback(error)
    else
      Github.Api.statuses.get {
        user: org,
        repo: reponame,
        sha: details.head.sha
      }, (error, statuses) ->
        if (error?)
          callback(error)
        else
          callback null, {
            title: details.title,
            url: details.html_url,
            infos: reponame,
            comments: "(#{details.head.ref} -> #{details.base.ref}) - " +
                      Moment(details.created_at).fromNow() + " - " +
                      details.comments + " comments" +
                      needAttention(details.mergeable, details.state),
            status: GhHelpers.buildStatus(statuses),
            avatar: details.user.gravatar_id,
            order: details.created_at
          }
isRepoInFilters = (name) ->
  _.some Configuration.Github.Filters, (filter) ->
    _.str.include name, filter

checkRecentDate = (createdAt, filter) ->
  period = if filter? then filter else 'weeks'
  #TODO: Check the different filter possibilities (weeks, days...)
  thisUnit = Moment().subtract(period, 1)
  Moment(createdAt).isAfter(thisUnit)

shouldBeDisplayed = (keyword, filter, title, createdAt) ->
  if (keyword is 'last' and filter? and _.isNaN(parseInt(filter)))
    keyword = 'with'

  if (keyword is 'recent' and createdAt?)
    checkRecentDate(createdAt, filter)
  else if (not filter?) then true
  else
    term = filter.toLowerCase()
    query = title.toLowerCase()
    if (keyword is 'without' and _.str.include(query, term)) then false
    else if (keyword is 'with' and not _.str.include(query, term)) then false
    else true

pickLastIfNeeded = (keyword, filter, list) ->
  if (keyword is 'last')
    number = if (filter? and not _.isNaN(parseInt(filter)))
      parseInt(filter)
    else 1

    _.first(list, number)
  else list

needAttention = (mergeable, state) ->
  warning = ""
  warning = if not mergeable then " - *NEED REBASE*" else warning
  warning = if state is 'closed' then " - *CLOSED*" else warning
  warning

getAllRepos = (keyword, filter, org, page, acc, globalCb) ->
  Github.Api.repos.getFromOrg { org: org, page: page, per_page: 100 }, (error, repos) ->
    if (error? or _.isEmpty(repos))
      globalCb(error, acc)
    else
      Async.concat repos, (repo, callback) ->
        if (isRepoInFilters(repo.name))
          Github.Api.pullRequests.getAll { user: Github.Org, repo: repo.name }, (error, prs) ->
            if (error?)
              callback error, []
            else
              Async.reduce prs, [],
                Async.apply (memo, pr, cb) ->
                  query = pr.title + repo.name + pr.user.login
                  if (shouldBeDisplayed(keyword, filter, query, pr.created_at))
                    getInfoPull Github.Org, repo.name, pr.number, (error, r) ->
                      memo.push r
                      cb error, memo
                  else
                    cb(error, memo)
              , (err, list) ->
                callback(err, list)
        else
          callback null, []
      , (err, result) ->
        if (err?)
          globalCb(err, null)
        else
          getAllRepos(keyword, filter, org, parseInt(page) + 1, acc.concat(result), globalCb)

module.exports = {
  name: "Pull Requests"
  description: "[ -url[s]- |
 without -filter- | with -filter- |
 recent [-unit-] |
 last [-number- | -filter-]
 ] List all Pull Requests of the organisation",
  action: pulls,
  isRepoInFilters: isRepoInFilters,
  shouldBeDisplayed: shouldBeDisplayed,
  pickLastIfNeeded: pickLastIfNeeded
}
