Configuration = require './configuration'
_ = require('underscore')._

Jira = Configuration.Jira
Async = require 'async'
XRegExp = require('xregexp').XRegExp
XRegExp.install 'natives'

Utils = require './utils'

jiraIssueUrlPattern =
  XRegExp "(http|https):\/\/#{Jira.Host}+(?<url>[a-zA-Z0-9\-\.,@\?^=%&;:\/~\+#]*[a-zA-Z0-9\-@\?^=%&;\/~\+#])?", 'i'

#TODO: Accept more than one id
issues = (fallback, id) ->
  # First we verify if the argument is an URL
  match = jiraIssuesUrlMatching(id)
  if (match)
    id = match[0].id

  fetchIssues id, (error, issues) ->
    if (error)
      Utils.fallback_printError fallback, error
    else
      Utils.fallback_printList fallback, _.map(issues, formatIssue)

fetchIssues = (id, callback) ->
  Jira.Api.findIssue id.toLowerCase(), (error, issue) ->
    if (not error? and not _.isEmpty(issue.fields.subtasks))
      Async.reduce issue.fields.subtasks, [issue], (memo, item, cb) ->
        Jira.Api.findIssue item.key.toLowerCase(), (err, subtask) ->
          if (err)
            cb null, memo
          else
            memo.push(subtask)
            cb null, memo
      , (err, result) ->
        callback err, result
    else
      callback error, [issue]

formatIssue = (issue) ->
  {
    title: issue.fields.summary,
    url: "https://" + Configuration.Nconf.get("jira").host + "/browse/" + issue.key,
    infos: resolveInfosMessage(issue),
    comments: resolveCommentsMessage(issue),
    status: resolveStatus(issue.fields.status),
    avatar: if issue.fields.assignee? then issue.fields.assignee.avatarUrls['24x24'],
    tails: if issue.fields.description? then [ issue.fields.description ]
  }

jiraIssuesUrlMatching = (url) ->
  issues = XRegExp.forEach url, jiraIssueUrlPattern, (matching) ->
    issue = matching.url.split('\/')
    this.push {
      id: issue[2]
    }
  , []
  issues if not _.isEmpty(issues)

resolveInfosMessage = (issue) ->
  message = issue.fields.project.name + ': ' + issue.fields.issuetype.name
  if Jira.StoryPointsField and issue.fields[Jira.StoryPointsField]?
    message += "(#{issue.fields[Jira.StoryPointsField]})"
  message

resolveCommentsMessage = (issue) ->
  message = issue.fields.comment.total + ' comments'
  if issue.fields.priority?
    message += " - *#{issue.fields.priority.name.toUpperCase()}*"
  message

resolveStatus = (status) ->
  if (status? and status.name == 'Closed')
    true
  else if (status? and status.name == 'Open')
    false
  else
    undefined

module.exports = {
  name: "Issues",
  description: "-id- | -url- Display details of a JIRA ticket",
  action: issues,
  jiraIssuesUrlMatching: jiraIssuesUrlMatching,
  resolveStatus: resolveStatus
}
