Albot
=====

[![Build Status](https://secure.travis-ci.org/boxuk/albot.png)](http://travis-ci.org/boxuk/albot)

Albot is a small command line tool built as an attempt to help us with our Developement process.

Usage
=====
 
      ./albot.coffee --help                                                                                                                                                                                                           

        Usage: albot.coffee [options] [command]

        Commands:

          pulls                  List all Pull Requests of the organisation
          help                   Display a list of available commands
          server                 Start albot to listen on Hipchat instead of the command line

        Options:

          -h, --help     output usage information
          -V, --version  output the version number

Server
======

Albot can also be use as an Hipchat bot.

      ./albot.coffee server

Will use the History API to poll the discussions and answer to his name.
The same commands can be used.

Note that the Hipchat API is limited to 100 requests by 5 minutes.
By default, 50 are used to poll the channel.

Configuration
=============

The default configuration is not very useful as you will need tokens for Hipchat and Github.

You can copy the .albot.json.template file and customise it for your needs. Just call it __.albot.json__
This file must be located either in the current directory (where you launch Albot) or in your home directory.

If you are more comfortable with env variables. You can use that too.

Hacking
=======

Don't hesitate to submit a Pull Request if you find it useful.
If not, submit an issue instead and tell us why!

If you don't know where to start. Look at the TODO file for any ideas of improvement or new command

Don't forget to add some tests.
We use Mocha, Chai and Nock.
