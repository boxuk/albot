Configuration = require './configuration'

Utils = require './utils'

help = (fallback) ->
  for key, value of list
    Utils.fallback_print(fallback) {
      title: key,
      comments: value.description
    }

# All the commands should have a fallback function or null as first argument
# Due to some Commander weirdness,
# it's better to use _.isString to check if an argument exists
#
# TODO: See if we can make that cleaner
list = {
  pulls: require('./pulls'),
  help: {
    name: "Help"
    description: "Display a list of available commands",
    action: help
  }
}

module.exports = list
