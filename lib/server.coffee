Configuration = require './configuration'

Async = require 'async'
_ = require('underscore')._

HipchatApi = require 'hipchat'

Commands = require './commands'
Cache = require './cache'

@rooms = new HipchatApi(Configuration.get("hipchat").token).Rooms
@channel = Configuration.get("hipchat").channel
@frequency = Configuration.get("hipchat").frequency

dispatch = (message) ->
  pattern = new RegExp("^#{Configuration.get("nickname")} ([a-z]+)( ([a-z\-]+))?$");
  request = message.match(pattern)
  if (request and request.length > 1)
    cmd = Commands[request[1]]
    cmd["arg"] = request[3] || "" if cmd
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
              command.action(command.arg)
          cb(null)
        , (err) ->
          Cache.store(lines.messages)
  , @frequency

module.exports = {
  dispatch: dispatch,
  action: server
}
