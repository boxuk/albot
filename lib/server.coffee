Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Async = require 'async'
Match = require 'match'
_ = require('underscore')._

HipchatApi = require 'hipchat'

Commands = require './commands'
Cache = require './cache'

@rooms = new HipchatApi(Nconf.get("hipchat").token).Rooms
@channel = Nconf.get("hipchat").channel
@frequency = Nconf.get("hipchat").frequency

dispatch = (message) ->
  pattern = new RegExp("^#{Nconf.get("nickname")} ([a-z]+)$");
  cmd = message.match(pattern)
  if (cmd)
    Commands[cmd[1]]

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
            dispatch(line.message).action()
          cb(null)
        , (err) ->
          Cache.store(lines.messages)
  , @frequency

module.exports = {
  dispatch: dispatch,
  action: server
}
