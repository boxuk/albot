Configuration = require './configuration'
_ = require('underscore')._

Github = Configuration.Github
Deploy = Configuration.Nconf.get('deploy')
Async = require 'async'
Spawn = require('child_process').spawn
Mkdirp = require 'mkdirp'
Temp = require 'temp'
Fs = require 'fs'
Path = require 'path'

Commands = require './commands'
Utils = require './utils'

prepareEnv = (repo, ref, callback) ->
  Temp.mkdir 'repo', (error, dirPath) ->
    if (error)
      callback(error)
    else
      Async.each Deploy.env, (file, cb) ->
        script = {}
        filePath = ""
        Async.waterfall [
          (waterCallback) ->
            Github.Api.repos.getContent { user: Github.Org, repo: repo, ref: ref, path: file }, waterCallback

          , (fileDetails, waterCallback) ->
            script = new Buffer(fileDetails.content, fileDetails.encoding).toString()
            filePath = fileDetails.path
            Mkdirp Path.join(dirPath, Path.dirname(file)), waterCallback

          , (made, waterCallback) ->
            Fs.writeFile Path.join(dirPath, filePath), script, waterCallback

        ], (waterr) ->
          cb(waterr)
      , (err) ->
        callback(err, dirPath)

deploy = (fallback, repo, branch) ->
  repo = Deploy.aliases[repo] || repo
  branch = if branch? and _.isString(branch) then branch else "master"
  if branch? and Deploy.branchArg? then Deploy.args.push(Deploy.branchArg.replace("{{branch}}", branch))

  prepareEnv repo, branch, (error, dirPath) ->
    if (error?)
      Utils.fallback_printError(fallback, error)
    else
      if (not Deploy.exec? or _.isEmpty(Deploy.exec))
        Utils.fallback_printError(fallback, "Deploy not configured.")
      else

        proc = Spawn Deploy.exec, Deploy.args, { cwd: dirPath }

        Utils.fallback_print(fallback)
          title: "Deploy started", infos: repo, comments: "(#{branch})", status: true
       
        logPath = Temp.path {suffix: ".log"}
        log = Fs.createWriteStream logPath
        proc.stdout.pipe log
        proc.stderr.pipe log

        proc.on 'exit', (code) ->
          if (code is 0)
            gist log, logPath, (err, url) ->
              Utils.fallback_print(fallback)
                title: "Successful deploy !", url: url, infos: repo, comments: "(#{branch})", status: true
          else
            gist log, logPath, (err, url) ->
              Utils.fallback_print(fallback) {
                title: "A problem occured during the deploy",
                url: url,
                infos: repo,
                comments: "(#{branch})",
                status: false
              }

        proc.on 'error', (error) ->
          gist log, logPath, (err, url) ->
            Utils.fallback_print(fallback) {
              title: "A problem occured during the deploy: #{error}",
              url: url,
              infos: repo,
              comments: "(#{branch})",
              status: false
            }

gist = (log, logPath, callback) ->
  Fs.readFile logPath, (error, data) ->
    data = data.toString()
    data = data.replace(new RegExp('\\\u001b\\[0m', 'g'), '')
    data = data.replace(new RegExp('\\\u001b\\[31m', 'g'), '')
    data = data.replace(new RegExp('✘', 'g'), '-')
    data = data.replace(new RegExp('✓', 'g'), '+')

    Github.Api.gists.edit { id: Deploy.gistId, files: {"history": { content: data } }}, (err, gist) ->
      if (err?) then callback(err) else callback(null, gist.html_url)

module.exports = {
  name: 'Deploy',
  description: '-project- | -alias- [-branch-] Deploy your projects with the configured command'
  action: deploy,
  prepareEnv: prepareEnv
}
