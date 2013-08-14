Nconf = require 'nconf'
_ = require('underscore')._

Fs = require 'fs'
Path = require 'path'

Funcster = require 'funcster'

HipchatApi = require 'hipchat'
GithubApi = require 'github'
Winston = require 'winston'
JiraApi = require('jira').JiraApi
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
      "env": [],
      "postProcessFile": ""
    },
    "amazon": {
      "key": "",
      "secret": "",
      "region": "eu-west-1"
    },
    "jira": {
      "host": "",
      "user": "",
      "password": ""
    }
  }

hipchat = new HipchatApi Nconf.get('hipchat').token

github = new GithubApi { version: "3.0.0", debug: Nconf.get("github").debug }
github.authenticate { type: "oauth", token: Nconf.get("github").token }

jira = new JiraApi('https', Nconf.get("jira").host, 443, Nconf.get("jira").user, Nconf.get("jira").password, 2)

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
  Jira: {
    Api: jira,
    Host: Nconf.get('jira').host,
    StoryPointsField: Nconf.get('jira').story_points_field
  },
  Winston: {
    initLogger: initLogger,
    logger: @logger || initLogger()
  },
  Deploy: _.extend(Nconf.get('deploy'), {
    postProcessFunction: if Nconf.get('deploy').postProcessFile then Funcster.deepDeserialize(
      { __js_function: Nconf.get('deploy').postProcessFile },
      { globals: { console: console } }
    )
  }),
  Version: JSON.parse(Fs.readFileSync(Path.resolve(__dirname, '../package.json'), 'utf8')).version
