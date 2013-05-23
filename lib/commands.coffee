Configuration = require './configuration'

Utils = require './utils'

help = (fallback) ->
  for key, value of list
    Utils.printWithFallback(fallback)(key, null, null, value.description)

# All the commands should have a fallback function or null as first argument
# Due to some Commander weirdness, it's better to use _.isString to check if an argument exists
#
# TODO: See if we can make that cleaner
list = {
  pulls: require('./commands/pulls'),
  help: {
    name: "Help"
    description: "Display a list of available commands",
    action: help
  }
}

module.exports = list
