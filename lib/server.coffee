Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Async = require 'async'
Match = require 'match'
_ = require('underscore')._

HipchatApi = require 'hipchat'

Commands = require './commands'

@rooms = new HipchatApi(Nconf.get("hipchat").token).Rooms
@channel = Nconf.get("hipchat").channel
@frequency = Nconf.get("hipchat").frequency

store = (messages) =>
  @cache = _.map(messages, (message) -> JSON.stringify(message))
cached = (line) =>
  _.contains(@cache, JSON.stringify(line))

dispatch = (line) ->
  pattern = new RegExp("^#{Nconf.get("nickname")} ([a-z]+)$");
  cmd = line.message.match(pattern)
  if (cmd)
    Commands[cmd[1]].action()

server = () =>
  @rooms.history @channel, (error, lines) ->
    if (error) then console.log(error)
    else if(lines)
      store(lines.messages)

  setInterval () =>
    @rooms.history @channel, (error, lines) ->
      if (error) then console.log(error)
      else if (lines)
        Async.each lines.messages, (line, cb) ->
          if (not cached(line))
            dispatch(line)
          cb(null)
        , (err) ->
          store(lines.messages)
  , @frequency

module.exports = server
