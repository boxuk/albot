#!/usr/bin/env coffee

Configuration = require './lib/configuration'
_ = require('underscore')._

Program = require 'commander'

Commands = require './lib/commands'

Program.version Configuration.Version

# Creating a Command entry for each corresponding JSON object
for key, value of Commands
  Program
    .command(key)
    .description(value.description)
    .action(_.partial(value.action, null))

Program
  .command('server')
  .description('Start albot to listen on Hipchat instead of the command line')
  .action(require('./lib/server').action)

Program.parse process.argv
