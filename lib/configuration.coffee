Nconf = require 'nconf'
Fs = require 'fs'
Path = require 'path'
HipchatApi = require 'hipchat'
GithubApi = require 'github'
Winston = require 'winston'
AWS = require 'aws-sdk'

userHome = () ->
  process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE

envSuffix = () ->
  if process.env.NODE_ENV then "." + process.env.NODE_ENV + ".json" else ".json"

# env override everything
# a local file comes second
# then, if nothing is found here, a file in HOME is used
Nconf
  .env()
  .file('local', '.albot' + envSuffix())
  .file('home', userHome() + '/.albot' + envSuffix())

Nconf
  .defaults {
    "nickname": "albot",
    "aliases": {},
    "disabledCommands": [],
    "github": {
      "repo_filter": "",
      "gravatar": false,
      "debug": false
    },
    "hipchat": {
      "frequency": 6000
    },
    "deploy": {
      "args": [],
      "env": []
    },
    "amazon": {
      "key": "",
      "secret": "",
      "region": ""
    }
  }

hipchat = new HipchatApi Nconf.get('hipchat').token

github = new GithubApi { version: "3.0.0", debug: Nconf.get("github").debug }
github.authenticate { type: "oauth", token: Nconf.get("github").token }

initLogger =
  (verbose = false) ->
    mode = if verbose then 'verbose' else 'info'

    @logger = new Winston.Logger({
      transports: [
        new (Winston.transports.Console)({ level: mode })
      ]
    }).cli()

    @logger

initAws =
  (aws) ->
    if (aws?)
      @aws = aws
    else
      credentials =
        {
          accessKeyId: Nconf.get("amazon").key,
          secretAccessKey: Nconf.get("amazon").secret,
          region: Nconf.get("amazon").region
        }

      AWS.config.update credentials
      @aws = AWS

    @aws

module.exports =
  Nconf: Nconf,
  Nickname: Nconf.get('nickname'),
  Github: {
    Api: github,
    Org: Nconf.get('github').organisation,
    Filters: Nconf.get('github').repo_filters,
    Gravatar: Nconf.get('github').gravatar
  },
  Hipchat: {
    Rooms: hipchat.Rooms,
    Channel: Nconf.get('hipchat').channel,
    Frequency: Nconf.get('hipchat').frequency
  },
  Amazon: {
    initAws: initAws,
    aws: @aws || initAws()
  },
  Winston: {
    initLogger: initLogger,
    logger: @logger || initLogger()
  },
  Version: JSON.parse(Fs.readFileSync(Path.resolve(__dirname, '../package.json'), 'utf8')).version
