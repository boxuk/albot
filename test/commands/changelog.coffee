Require = require('covershot').require.bind(null, require)
should = require('chai').should()

Commands = Require '../../lib/commands'
Nock = Require 'nock'
Moment = require 'moment'
Querystring = require 'querystring'

describe 'Commands', () ->
  describe '#changelog()', () ->
    it 'Can display the commits of a PR', (done) ->
      Nock('https://api.github.com')
        .persist()
        .get('/repos/testorg/test-deployable/pulls/620/commits?access_token=testtoken')
        .reply(200, [{
            "commit": {
              "message": "Commit message"
              "committer": {
                "date": "2011-01-26T19:01:12Z"
              }
            },
            "committer": {
              "gravatar_id": "lksajglkfdjg"
            }
          }])

      Commands.changelog.action (object) ->
        object.title.should.be.equal 'Commit message'
        object.comments.should.be.equal Moment("2011-01-26T19:01:12Z").fromNow()
        object.avatar.should.be.equal "lksajglkfdjg"
        done()
      , 't', 'pr', '620'

    it 'Can gist the commits of a PR', (done) ->
      dateGist = Moment("2011-01-26T19:01:12Z").fromNow()

      Nock('https://api.github.com')
        .persist()
        .get('/repos/testorg/test-deployable/pulls/620/commits?access_token=testtoken')
        .reply(200, [{
            "commit": {
              "message": "Commit message"
              "committer": {
                "date": "2011-01-26T19:01:12Z"
              }
            },
            "committer": {
              "gravatar_id": "lksajglkfdjg"
            }
          }])
        .intercept('/gists/test-gist-cl?access_token=testtoken', 'PATCH', {
          files: {
            "history.md": {
              content: "- Commit message - *#{dateGist}*\n"
            }
          }
        })
        .reply(200, {
            "html_url": "https://gist.github.com/2"
          })

      Commands.changelog.action (object) ->
        object.title.should.be.equal 'View the changelog'
        object.url.should.be.equal 'https://gist.github.com/2'
        done()
      , 't', 'pr', '620', 'save'

    it 'Can display the commits of master since a period', (done) ->
      dateArg = Querystring.escape('"' + Moment().utc().subtract('weeks', 2).format("YYYY-MM-DDTHH:mm:ss") + '.000Z"')

      Nock('https://api.github.com')
        .persist()
        .get("/repos/testorg/test-deployable/commits?since=#{dateArg}&access_token=testtoken")
        .reply(200, [{
            "commit": {
              "message": "Commit message from master"
              "committer": {
                "date": "2011-01-26T19:01:12Z"
              }
            },
            "committer": {
              "gravatar_id": "lksajglkfdjg"
            }
          }])

      Commands.changelog.action (object) ->
        object.title.should.be.equal 'Commit message from master'
        object.comments.should.be.equal Moment("2011-01-26T19:01:12Z").fromNow()
        object.avatar.should.be.equal "lksajglkfdjg"
        done()
      , 't', 'since', '2', 'weeks'

    it 'Can display the commits between two references', (done) ->
      Nock('https://api.github.com')
        .persist()
        .get("/repos/testorg/test-deployable/compare/46...47?access_token=testtoken")
        .reply(200, {
            "commits": [{
              "commit": {
                "message": "Merge should appear"
                "committer": {
                  "date": "2011-01-26T19:01:12Z"
                }
              },
              "committer": {
                "gravatar_id": "lksajglkfdjg"
              }
            }, {
              "commit": {
                "message": "Commit message from master"
                "committer": {
                  "date": "2011-01-26T19:01:12Z"
                }
              },
              "committer": {
                "gravatar_id": "lksajglkfdjg"
              }
            }]
          })

      Commands.changelog.action (object) ->
        object.title.should.be.equal 'Commit message from master'
        object.comments.should.be.equal Moment("2011-01-26T19:01:12Z").fromNow()
        object.avatar.should.be.equal "lksajglkfdjg"
        done()
      , 't', 'between', '46..47'
