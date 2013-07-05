#!/usr/bin/env coffee

Configuration = require './lib/configuration'
_ = require('underscore')._

Program = require 'commander'

Commands = require './lib/commands'

# Initialiase the logger with the right level before anything
initLoggerBefore = (fonction) ->
  _.wrap fonction, (f) ->
    Configuration.Winston.initLogger Program.verbose
    f.apply null, arguments

# Defining available options
Program
  .version(Configuration.Version)
  .option('-v, --verbose', 'Enable the verbose mode')

# Creating a Command entry for each corresponding JSON object
for key, value of Commands
  Program
    .command(key)
    .description(value.description)
    .action initLoggerBefore(_.partial(value.action, null))

# Creating special server command
Program
  .command('server')
  .description('Start albot to listen on Hipchat instead of the command line')
  .action initLoggerBefore(require('./lib/server').action)

Program.parse process.argv
