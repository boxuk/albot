Configuration = require './configuration'

Async = require 'async'
Moment = require 'moment'
_ = require('underscore')._

GitHubApi = require 'github'

Utils = require './utils'

@github = new GitHubApi { version: "3.0.0", debug: Configuration.get("github").debug }
@github.authenticate { type: "oauth", token: Configuration.get("github").token }

@org = Configuration.get("github").organisation

@githubUrlPattern = new RegExp('(http|https):\/\/github.com+([a-z0-9\-\.,@\?^=%&;:\/~\+#]*[a-z0-9\-@\?^=%&;\/~\+#])?', 'i')

isRepoInFilters = (name) ->
  repo_filters = Configuration.get("github").repo_filters
  _.some repo_filters, (filter) ->
    name.indexOf(filter) > -1

checkRecentDate = (createdAt, filter) ->
  period = if _.isString(filter) then filter else 'weeks'
  #TODO: Check the different filter possibilities (weeks, days...)
  thisUnit = Moment().subtract(period, 1)
  Moment(createdAt).isAfter(thisUnit)

shouldBeDisplayed = (keyword, filter, title, createdAt) ->
  if (keyword is 'last' and _.isString(filter) and _.isNaN(parseInt(filter))) then keyword = 'with'

  if (keyword is 'recent' and createdAt?) then checkRecentDate(createdAt, filter)
  else if (not _.isString(filter)) then true
  else 
    term = filter.toLowerCase()
    query = title.toLowerCase()
    if (keyword is 'without' and query.indexOf(term) > -1) then false
    else if (keyword is 'with' and query.indexOf(term) == -1) then false
    else true

pickLastIfNeeded = (keyword, filter, list) ->
  if (keyword is 'last')
    number = if (_.isString(filter) and not _.isNaN(parseInt(filter))) then parseInt(filter) else 1
    _.first(list, number)
  else list

buildStatus = (statuses) ->
  status = statuses[0] if statuses?
  if not status? or not status.state? or status.state is 'pending' then undefined else status.state is 'success'

needAttention = (mergeable, state) ->
  warning = ""
  warning = if not mergeable then " - *NEED REBASE*" else warning
  warning = if state is 'closed' then " - *CLOSED*" else warning
  warning

getInfoPull = (org, reponame, number, callback) =>
  @github.pullRequests.get {user: org, repo: reponame, number: number}, (error, details) =>
    @github.statuses.get {user: org, repo: reponame, sha: details.head.sha}, (error, statuses) ->
      callback error, {
        title: details.title,
        url: details.html_url,
        infos: reponame,
        comments: Moment(details.created_at).fromNow() + " - " + details.comments + " comments" + needAttention(details.mergeable, details.state),
        status: buildStatus(statuses),
        avatar: details.user.gravatar_id,
        order: details.created_at
      }

#TODO: Speeeeeeeeeeed
pulls = (fallback, keyword, filter) =>

  # First we verifyif the argument is an URL
  if (_.isString(keyword) and keyword.match(@githubUrlPattern) and keyword.indexOf('pull') > -1)
    pull = keyword.match(@githubUrlPattern)[2].split('\/')
    getInfoPull pull[1], pull[2], pull[4], (error, result) ->
      if (not error)
        Utils.printWithFallback(fallback)(result.title, result.url, result.infos, result.comments, result.status, result.avatar)
  else
    @github.repos.getFromOrg {org: @org, per_page: 100}, (error, repos) =>
      Async.concat repos, (repo, callback) =>
        if (isRepoInFilters(repo.name))
          @github.pullRequests.getAll {user: @org, repo: repo.name}, (error, prs) =>
            if (error)
              callback(error)
            else
              Async.reduce prs, [],
                Async.apply (memo, pr, cb) =>
                  query = pr.title + repo.name + pr.user.login
                  if (shouldBeDisplayed(keyword, filter, query, pr.created_at))
                    getInfoPull @org, repo.name, pr.number, (error, result) ->
                      memo.push result
                      cb null, memo
                  else
                    cb(error, memo)
              , (err, list) ->
                callback(err, list)
        else
          callback(null, [])
      , (err, list) ->
        if (err)
          console.log "An error occured"
        else 
          Utils.printListWithFallback(fallback, list, _.partial(pickLastIfNeeded, keyword, filter))

module.exports = {
  name: "Pull Requests"
  description: "[ -url- | without -filter- | with -filter- | recent [-unit-] | last [-number- | -filter-]] List all Pull Requests of the organisation",
  action: pulls,
  isRepoInFilters: isRepoInFilters,
  shouldBeDisplayed: shouldBeDisplayed,
  pickLastIfNeeded: pickLastIfNeeded
}
