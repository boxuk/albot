Configuration = require './configuration'
_ = require('underscore')._

Async = require 'async'
Moment = require 'moment'

Hipchat = Configuration.Hipchat
Winston = Configuration.Winston
Commands = require './commands'
Cache = require './cache'
Utils = require './utils'

# TODO: Loop or XRegExp
pattern = new RegExp "^#{Configuration.Nickname} ([a-zA-Z0-9]+)
( ([a-zA-Z0-9\-\+\/\.\:\_]+))?
( ([a-zA-Z0-9\-\+\/\.\:\_]+))?
( ([a-zA-Z0-9\-\+\/\.\:\_]+))?
( ([a-zA-Z0-9\-\+\/\.\:\_]+))?
( ([a-zA-Z0-9\-\+\/\.\:\_]+))?
( ([a-zA-Z0-9\-\+\/\.\:\_]+))?$"

dispatch = (message, from) ->
  if (not from? or from.name != Configuration.Nickname)

    if (not message.match(new RegExp "#{Configuration.Nickname}"))
      #TODO: This definitively need NOT to be a special case hard coded
      if (require('./gh_helpers').githubPRUrlMatching(message))
        cmd = Commands.pulls
        if (cmd)
          cmd.args = []
          cmd.args.push message
        cmd
    else
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
  freq = if frequency? then frequency else Hipchat.Frequency

  Hipchat.Rooms.history Hipchat.Channel, (error, lines) ->
    if (error?) then Winston.logger.error("An error occured while fetching history: #{JSON.stringify(error)}")
    else if(lines)
      Cache.store(lines.messages)

  intervalId = setInterval () ->
    Hipchat.Rooms.history Hipchat.Channel, (error, lines) ->
      if (error?) then Winston.logger.error("An error occured while fetching history: #{JSON.stringify(error)}")
      else if (lines)
        Async.each lines.messages, (line, cb) ->
          if (not Cache.cached(line))
            command = dispatch(line.message, line.from)

            if (command)
              if testCallback? and _.isFunction(testCallback)
                testCallback(intervalId, command)
              else
                Winston.logger.info "Command #{command.name} detected #{Moment().format()}"
                Winston.logger.verbose "With arguments: #{JSON.stringify(command.args)}"

                _.partial(command.action, Utils.render).apply null, command.args
          cb(null)
        , (err) ->
          Cache.store lines.messages
  , freq

  if (not _.isFunction(testCallback))
    Winston.logger.info "Bot listening to Hipchat channel: #{Hipchat.Channel}"
    Winston.logger.verbose "Verbose mode activated"

module.exports = {
  dispatch: dispatch,
  action: server
}
