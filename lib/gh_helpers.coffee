Configuration = require './configuration'
_ = require('underscore')._

githubUrlPattern = new RegExp "(http|https):\/\/github.com+([a-z0-9\-\.,@\?^=%&;:\/~\+#]*[a-z0-9\-@\?^=%&;\/~\+#])?",'i'

githubPRUrlMatching = (url) ->
  matching = url.match(githubUrlPattern) if _.isString(url)
  if (matching and _.str.include(url, 'pull'))
    pull = matching[2].split('\/')
    {
      org: pull[1]
      repo: pull[2]
      number: pull[4]
    }

buildStatus = (statuses) ->
  status = statuses[0] if statuses?
  if not status? or not status.state? or status.state is 'pending'
    undefined
  else status.state is 'success'

module.exports = {
  githubPRUrlMatching: githubPRUrlMatching,
  buildStatus: buildStatus
}
