Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Async = require 'async'
_ = require('underscore')._

HipchatApi = require 'hipchat'

@rooms = new HipchatApi(Nconf.get("hipchat_token")).Rooms

server = () =>
  @rooms.history "albot", (error, lines) =>
    if (error) then console.log(error)
    else if(lines)
      @cache = _.map(lines.messages, (m) -> JSON.stringify(m))

  setInterval () =>
    @rooms.history "albot", (error, lines) =>
      if (error) then console.log(error)
      else if (lines)
        Async.each lines.messages, (line, cb) =>
          if (not _.contains(@cache, JSON.stringify(line)))
            if (line.message is "albot pulls")
              require('./commands').pulls.action()
          cb(null)
        , (err) =>
          @cache = _.map(lines.messages, (m) -> JSON.stringify(m))
  , 5000

module.exports = server
