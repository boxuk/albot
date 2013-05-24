Configuration = require './configuration'

Async = require 'async'
_ = require('underscore')._

HipchatApi = require 'hipchat'

Commands = require './commands'
Cache = require './cache'
Utils = require './utils'

@rooms = new HipchatApi(Configuration.get("hipchat").token).Rooms
@channel = Configuration.get("hipchat").channel
@frequency = Configuration.get("hipchat").frequency

dispatch = (message) ->
  # Loop
  pattern = new RegExp "^#{Configuration.get("nickname")} ([a-zA-Z0-9]+)
( ([a-zA-Z0-9\-\+\/\.\:]+))?
( ([a-zA-Z0-9\-\+]+))?
( ([a-zA-Z0-9\-\+]+))?
( ([a-zA-Z0-9\-\+]+))?
( ([a-zA-Z0-9\-\+]+))?$"

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

server = (frequency, testCallback) =>
  freq = if _.isString(frequency) then frequency else @frequency

  @rooms.history @channel, (error, lines) ->
    if (error) then console.log(error)
    else if(lines)
      Cache.store(lines.messages)

  intervalId = setInterval () =>
    @rooms.history @channel, (error, lines) ->
      if (error) then console.log(error)
      else if (lines)
        Async.each lines.messages, (line, cb) ->
          if (not Cache.cached(line))
            command = dispatch(line.message)
            if (command)
              if testCallback? and _.isFunction(testCallback)
                testCallback(intervalId, command)
              else
                _.partial(command.action, Utils.render).apply null, command.args
          cb(null)
        , (err) ->
          Cache.store lines.messages
  , freq

  if (not _.isFunction(testCallback))
    console.log "Bot listening to Hipchat channel: #{@channel}"

module.exports = {
  dispatch: dispatch,
  action: server
}
