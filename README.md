Albot [![Build Status](https://secure.travis-ci.org/boxuk/albot.png)](http://travis-ci.org/boxuk/albot) [![Coverage Status](https://coveralls.io/repos/boxuk/albot/badge.png?branch=coveralls)](https://coveralls.io/r/boxuk/albot?branch=master) [![Dependency Status](https://gemnasium.com/boxuk/albot.png)](https://gemnasium.com/boxuk/albot)
=====

Albot is a small command line tool built as an attempt to help us with our Developement process

Installation
============

      npm install -g albot

Usage
=====
 
      $ albot --help                                                                                                                                                                                                           

        Usage: albot.coffee [options] [command]

        Commands:

          pulls                  [ <url> | without <filter> | with <filter> | recent [<unit>] | last [<number> | <filter>]] List all Pull Requests of the organisation
          help                   Display a list of available commands
          server                 Start albot to listen on Hipchat instead of the command line

        Options:

          -h, --help     output usage information
          -V, --version  output the version number

Pulls
=====

This command display the Pull Requests of all the repositories in your organisation
(For which the name correspond the filters you have configured).

The results are sorted by dates.

On top of that, you have access to more on-demand filters.

To only display the Pull Request that contains a term (The search is case insensitive):

      $ albot pulls with term

You can use this feature to display the Pull Request of a particular user:

      $ albot pulls with athieriot

The opposite is also available. Show all the Pull Requests that does NOT correspond to a term:

      $ albot pulls without WIP

You can as well display only recent Pull Requests

      $ albot pulls recent

By default, it's a week. But you can ask for a month, a year and so on. (All usable keys are here: [Moment#add](http://momentjs.com/docs/#/manipulating/add/))

      $ albot pulls recent months
      
I you need more, you can quickly show the last Pull Requests

      $ albot pulls last

Or the last ones

      $ albot pulls last 5

You can even have the last Pull Request filtered like 'with'

      $ albot pulls last athieriot

Finally, if you are lazy (like me), you can copy/paste an URL from your browser

      $ albot pulls https://github.com/flatiron/nock/pull/110

Example on Hipchat:

![hipchat - web chat](https://f.cloud.github.com/assets/661901/550556/8410e2fe-c314-11e2-9c1f-eb2f56489e4b.png)

Server
======

Albot can also be use as an Hipchat bot.

      $ albot server

Will use the History API to poll the discussions and answer to his name.
The same commands can be used.

Note that the Hipchat API is limited to 100 requests by 5 minutes.
By default, 50 are used to poll the channel.
Be careful, it's very short.

Configuration
=============

The default configuration is not very useful as you will need tokens for Hipchat and Github.

You can copy the .albot.json.template file and customise it for your needs. Just call it __.albot.json__
This file must be located either in the current directory (where you launch Albot) or in your home directory.

If you are more comfortable with env variables. You can use that too.

- __nickname__, The nickname of the bot. It/He/She will respond to it. Default: "albot"
- __github__
 - __organisation__, The name of your Github organisation
 - __token__ , The Github API token
 - __gravatar__, Display (or not) the gravatar of the Pull Request creators. Default: false
 - __repo_filters__, An array of term used to display Pull Requests. The terms must be included in repos name. Default: [""]
- __hipchat__
 - __channel__, The Hipchat channel to listen to in server mode
 - __token__, The Hipchat API token
 - __frequency__, Polling frequency. Default: 6000

Hacking
=======

Don't hesitate to submit a Pull Request if you find it useful.
If not, submit an issue instead and tell us why!

If you don't know where to start. Look at the TODO file for any ideas of improvement or new command

Don't forget to add some tests. We use Mocha, Chai and Nock.
