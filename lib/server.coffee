Configuration = require './configuration'
_ = require('underscore')._

Async = require 'async'
Moment = require 'moment'

Hipchat = Configuration.Hipchat
Commands = require './commands'
Cache = require './cache'
Utils = require './utils'

dispatch = (message) ->
  # TODO: Loop
  pattern = new RegExp "^#{Configuration.Nickname} ([a-zA-Z0-9]+)
( ([a-zA-Z0-9\-\+\/\.\:]+))?
( ([a-zA-Z0-9\-\+\/\.\:]+))?
( ([a-zA-Z0-9\-\+\/\.\:]+))?
( ([a-zA-Z0-9\-\+\/\.\:]+))?
( ([a-zA-Z0-9\-\+\/\.\:]+))?
( ([a-zA-Z0-9\-\+\/\.\:]+))?$"

  request = message.match(pattern)
  if (request and request.length > 1)
    cmd = Commands[request[1]]
    if (cmd)
      cmd.args = []
      cmd.args.push request[3]
      cmd.args.push request[5]
      cmd.args.push request[7]
      cmd.args.push request[9]
      cmd.args.push request[11]
    cmd

server = (frequency, testCallback) ->
  freq = if _.isString(frequency) then frequency else Hipchat.Frequency

  Hipchat.Rooms.history Hipchat.Channel, (error, lines) ->
    if (error?) then console.log("An error occured while fetching history: #{JSON.stringify(error)}")
    else if(lines)
      Cache.store(lines.messages)

  intervalId = setInterval () ->
    Hipchat.Rooms.history Hipchat.Channel, (error, lines) ->
      if (error?) then console.log("An error occured while fetching history: #{JSON.stringify(error)}")
      else if (lines)
        Async.each lines.messages, (line, cb) ->
          if (not Cache.cached(line))
            command = dispatch(line.message)
            if (command)
              if testCallback? and _.isFunction(testCallback)
                testCallback(intervalId, command)
              else
                console.log("Command #{command.name} detected #{Moment().format()}")
                _.partial(command.action, Utils.render).apply null, command.args
          cb(null)
        , (err) ->
          Cache.store lines.messages
  , freq

  if (not _.isFunction(testCallback))
    console.log "Bot listening to Hipchat channel: #{Hipchat.Channel}"

module.exports = {
  dispatch: dispatch,
  action: server
}
