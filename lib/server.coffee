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
  pattern = new RegExp("^#{Configuration.get("nickname")} ([a-z]+)( ([a-z\-]+))?( ([a-z\-]+))?( ([a-z\-]+))?( ([a-z\-]+))?( ([a-z\-]+))?$")
  request = message.match(pattern)
  if (request and request.length > 1)
    cmd = Commands[request[1]]
    cmd["arg1"] = request[3] || "" if cmd
    cmd["arg2"] = request[5] || "" if cmd
    cmd["arg3"] = request[7] || "" if cmd
    cmd["arg4"] = request[9] || "" if cmd
    cmd["arg5"] = request[11] || "" if cmd
    cmd

server = () =>
  @rooms.history @channel, (error, lines) ->
    if (error) then console.log(error)
    else if(lines)
      Cache.store(lines.messages)

  setInterval () =>
    @rooms.history @channel, (error, lines) ->
      if (error) then console.log(error)
      else if (lines)
        Async.each lines.messages, (line, cb) ->
          if (not Cache.cached(line))
            command = dispatch(line.message)
            if (command)
              _.partial(command.action, Utils.render)(command.arg1, command.arg2, command.arg3, command.arg4, command.arg5)
          cb(null)
        , (err) ->
          Cache.store(lines.messages)
  , @frequency

module.exports = {
  dispatch: dispatch,
  action: server
}
