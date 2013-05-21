Nconf = require 'nconf'

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
    "github": {
      "repo_filter": "",
      "gravatar": false,
      "debug": false
    },
    "hipchat": {
      "frequency": 6000
    }
  }

module.exports = Nconf
