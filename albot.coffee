#!/usr/bin/env coffee

Program = require 'commander'
Fs = require 'fs'

# Configuration definition.
# TODO: Exporting that in a specific module
Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Commands = require './lib/commands'

Program.version JSON.parse(Fs.readFileSync('./package.json', 'utf8')).version

# Creating a Command entry for each corresponding JSON object
for key, value of Commands
  Program
    .command(key)
    .description(value.description)
    .action(value.action)

Program
  .command('server')
  .description('Start albot to listen on Hipchat instead of the command line')
  .action(require('./lib/server').action)

Program.parse process.argv
