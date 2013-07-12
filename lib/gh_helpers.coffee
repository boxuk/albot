Configuration = require './configuration'
_ = require('underscore')._

XRegExp = require('xregexp').XRegExp
XRegExp.install 'natives'

ghUrlPattern = XRegExp "(http|https):\/\/github.com+(?<url>[a-z0-9\-\.,@\?^=%&;:\/~\+#]*[a-z0-9\-@\?^=%&;\/~\+#])?", 'i'

githubPRUrlMatching = (url) ->
  prs = XRegExp.forEach url, ghUrlPattern, (matching) ->
    if (matching and _.str.include(url, 'pull'))
      pull = matching.url.split('\/')
      this.push {
        org: pull[1]
        repo: pull[2]
        number: pull[4]
      }
  , []
  prs if not _.isEmpty(prs)

buildStatus = (statuses) ->
  status = statuses[0] if statuses?
  if not status? or not status.state? or status.state is 'pending'
    undefined
  else status.state is 'success'

module.exports = {
  githubPRUrlMatching: githubPRUrlMatching,
  buildStatus: buildStatus
}
