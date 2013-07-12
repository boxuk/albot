# Albot [![Build Status](https://secure.travis-ci.org/boxuk/albot.png)](http://travis-ci.org/boxuk/albot) [![Coverage Status](https://coveralls.io/repos/boxuk/albot/badge.png?branch=master)](https://coveralls.io/r/boxuk/albot?branch=master) [![Dependency Status](https://gemnasium.com/boxuk/albot.png)](https://gemnasium.com/boxuk/albot) [![NPM version](https://badge.fury.io/js/albot.png)](http://badge.fury.io/js/albot)

Albot is a small command line tool built as an attempt to help us with our Developement process

You can find a better version of this documentation here: [http://boxuk.github.io/albot/](http://boxuk.github.io/albot/)

## Installation

      npm install -g albot

You will just need Coffeescript

      npm install -g coffee-script

## Example on Hipchat:

![hipchat - web chat](https://f.cloud.github.com/assets/661901/550556/8410e2fe-c314-11e2-9c1f-eb2f56489e4b.png)

## Usage
 
      $ albot --help                                                                                                                                                                                                           

        Usage: albot.coffee [options] [command]

        Commands:

          pulls                  [ <url[s]> | without <filter> | with <filter> | recent [<unit>] | last [<number> | <filter>]] List all Pull Requests of the organisation
          deploy                 <project> [ | <alias>] [<branch>] Deploy your projects with the configured command
          changelog              <project> [ | <alias>] <pr> <number> | <since> <number> <period> | <between> <tag-range> [save] List changelog for a given PR, period, range
          amazon                 [ instances [ with <term> ] ] Display various informations about your Amazon infrastructure
          help                   Display a list of available commands
          server                 Start albot to listen on Hipchat instead of the command line

        Options:

          -h, --help     output usage information
          -V, --version  output the version number
          -v, --verbose  Enable the verbose mode

## Commands

### Pulls

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

Finally, if you are lazy (like me), you can copy/paste one URL from your browser

      $ albot pulls https://github.com/flatiron/nock/pull/110

Or more

      $ albot pulls https://github.com/flatiron/nock/pull/110 https://github.com/flatiron/nock/pull/109

### Deploy

This command will launch your favourite deployment script in a specific environement.
Environnement which is created by downloading files on your Github repository.

At the end, a Gist will be updated with the logs of the execution.

      $ albot deploy webapp

Will download the configured files ( __env__ property) from the branch master of __yourorg/webapp__ 
Then launch the deploy script in this temporary directory.

You can also specify a branch

      $ albot deploy webapp feature

Warning: This task requires quite more configuration.

The standard stuff are the script name, the list of arguments and the list of the files you want to have for your environement.

    "exec": "script",
    "args": ["arg1"],
    "env": ["README.md", "app/config/prod.json"],

You can also specify the way the branch name is passed to the script. {{branch}} will be replaced by the argument value.

    "branchArg": "-Sbranch={{branch}}",

If you have big project names, you can set pairs of key/value as aliases

    "webapp": "client-webapp-front"

Don't forget to pre-create a Gist and set the id.
We choose not to create a Gist automatically to avoid a ridiculously high number of those.

    "gistId": "sha1"

### Changelog

Changelog allows you to generate the change log of you Git commits history.
All the commit messages that start by "Merge" will be discarded.

You can get the changes for a specified Pull Request 

     $ albot changelog webapp pr 620

Or copy/paste a URL from your browser

      $ albot changelog https://github.com/flatiron/nock/pull/110

The changes of the master branch since a certain period
Like in the Pulls command, all usable keys comes from Moment.js here: [Moment#add](http://momentjs.com/docs/#/manipulating/add/)

     $ albot changelog webapp since 2 months

And the difference between two git references

     $ albot changelog webapp between 43..45

If you want to store the result in a Gist instead, just use the "save" keyword at the end.
Available in all flavour

     $ albot changelog webapp between 43..45 save

### Amazon

Display substantial informations about your Amazon infrastructure.
Like the list of your EC2 instances.

     $ albot amazon instances

Will display all the instances available on your account.

Interestingly, if you have DNS configured in Route53, this route will be displayed instead of the Public DNS.

If some of your instances are behind an ElasticLoadBalancer, more details will be provided for it.

You can, as always, filter the result list

     $ albot amazon instances with live

### Server

Albot can also be use as an Hipchat bot.

      $ albot server

Will use the History API to poll the discussions and answer to his name.
The same commands can be used.

Note that the Hipchat API is limited to 100 requests by 5 minutes.
By default, 50 are used to poll the channel.
Be careful, it's very short.

As a special feature in server mode:
If any Pull Request URL is detected anywhere in a message (even not prefixed by the name of the bot) then, the details of this PR will be printed the same way than ```albot pulls <url>```

## Configuration

The default configuration is not very useful as you will need tokens for Hipchat and Github.

You can copy the .albot.json.template file and customise it for your needs. Just call it __.albot.json__
This file must be located either in the current directory (where you launch Albot) or in your home directory.

If you are more comfortable with env variables. You can use that too.

- __nickname__, The nickname of the bot. It/He/She will respond to it. Default: "albot"
- __aliases__, Default: {}
- __disabledCommands__, A list of commands you don't want to use. Default: []
- __github__
 - __organisation__, The name of your Github organisation
 - __token__ , The Github API token
 - __gravatar__, Display (or not) the gravatar of the Pull Request creators. Default: false
 - __repo_filters__, An array of term used to display Pull Requests. The terms must be included in repos name. Default: [""]
- __hipchat__
 - __channel__, The Hipchat channel to listen to in server mode
 - __token__, The Hipchat API token
 - __frequency__, Polling frequency. Default: 6000
- __deploy__
 - __exec__, The script to execute as deployment
 - __args__, A list of arguments to pass to. Default: []
 - __branchArg__, Another argument with the branch name. Default: {{branch}}
 - __env__, List of files do download from Github and create a directory with. Default: []
 - __gistId__, Gist id for the execution logs
- __changelog__,
 - __gistId__, Gist id for the saved changelogs
- __amazon__,
 - __key__, The Amazon Key
 - __secret__, Amazon Secret
 - __region__, The region of your instances

## Hacking

Don't hesitate to submit a Pull Request if you find it useful.
If not, submit an issue instead and tell us why!

If you don't know where to start. Look at the TODO file for any ideas of improvement or new command

Don't forget to add some tests. We use Mocha, Chai and Nock.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/boxuk/albot/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

