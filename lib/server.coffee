Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Async = require 'async'
_ = require('underscore')._

HipchatApi = require 'hipchat'

Commands = require './commands'
Cache = require './cache'

@rooms = new HipchatApi(Nconf.get("hipchat").token).Rooms
@channel = Nconf.get("hipchat").channel
@frequency = Nconf.get("hipchat").frequency

dispatch = (message) ->
  pattern = new RegExp("^#{Nconf.get("nickname")} ([a-z]+)( ([a-z\-]+))?$");
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
