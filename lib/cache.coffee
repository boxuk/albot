Configuration = require './configuration'
_ = require('underscore')._

cache = []

store = (messages) ->
  cache = _.map(messages, (message) -> JSON.stringify(message))

cached = (line) ->
  _.contains(cache, JSON.stringify(line))

module.exports = {
  store: store,
  cached: cached
}
