Require = require('covershot').require.bind(null, require)
should = require('chai').should()

Changelog = Require '../../lib/changelog'
Nock = Require 'nock'
Moment = require 'moment'
Querystring = require 'querystring'

describe 'Commands', () ->
  describe '#changelog()', () ->
    it 'Can display the commits of a PR based on an URL', (done) ->
      Nock('https://api.github.com')
        .persist()
        .get('/repos/testorg-ext/god/pulls/156/commits?access_token=testtoken')
        .reply(200, [{
            "sha": "shaman1",
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
        .get('/repos/testorg-ext/god/statuses/shaman1?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])

      Changelog.action (object) ->
        object.title.should.be.equal 'Commit message'
        object.url.should.be.equal "https://github.com/testorg-ext/god/commit/shaman1"
        object.comments.should.be.equal Moment("2011-01-26T19:01:12Z").fromNow()
        object.avatar.should.be.equal "lksajglkfdjg"
        object.status.should.be.equal true
        done()
      , 'https://github.com/testorg-ext/god/pull/156'

    it 'Can display the commits of a PR', (done) ->
      Nock('https://api.github.com')
        .persist()
        .get('/repos/testorg/test-deployable/pulls/620/commits?access_token=testtoken')
        .reply(200, [{
            "sha": "shaman2",
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
        .get('/repos/testorg/test-deployable/statuses/shaman2?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])

      Changelog.action (object) ->
        object.title.should.be.equal 'Commit message'
        object.url.should.be.equal "https://github.com/testorg/test-deployable/commit/shaman2"
        object.comments.should.be.equal Moment("2011-01-26T19:01:12Z").fromNow()
        object.avatar.should.be.equal "lksajglkfdjg"
        object.status.should.be.equal true
        done()
      , 't', 'pr', '620'

    it 'Can gist the commits of a PR', (done) ->
      dateGist = Moment("2011-01-26T19:01:12Z").fromNow()

      Nock('https://api.github.com')
        .persist()
        .get('/repos/testorg/test-deployable/pulls/620/commits?access_token=testtoken')
        .reply(200, [{
            "sha": "shaman3",
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
        .get('/repos/testorg/test-deployable/statuses/shaman3?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])
        .intercept('/gists/test-gist-cl?access_token=testtoken', 'PATCH', {
          files: {
            "history.md": {
              content: "- Commit message - *#{dateGist}*\n"
            }
          }
        })
        .reply(200, {
            "html_url": "https://gist.github.com/2",
            "history": [{
              "version": "123456"
            }] 
          })

      Changelog.action (object) ->
        object.title.should.be.equal 'View the changelog'
        object.url.should.be.equal 'https://gist.github.com/2/123456'
        done()
      , 't', 'pr', '620', 'save'

    it 'Can display the commits of master since a period', (done) ->
      dateArg = Querystring.escape('"' + Moment().utc().subtract('weeks', 2).format("YYYY-MM-DDTHH:mm:ss") + '.000Z"')

      Nock('https://api.github.com')
        .persist()
        .get("/repos/testorg/test-deployable/commits?since=#{dateArg}&access_token=testtoken")
        .reply(200, [{
            "sha": "shaman4",
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
        .get('/repos/testorg/test-deployable/statuses/shaman4?access_token=testtoken')
        .reply(200, [
            {
              "state": "failure"
            }
          ])

      Changelog.action (object) ->
        object.title.should.be.equal 'Commit message from master'
        object.url.should.be.equal "https://github.com/testorg/test-deployable/commit/shaman4"
        object.comments.should.be.equal Moment("2011-01-26T19:01:12Z").fromNow()
        object.avatar.should.be.equal "lksajglkfdjg"
        object.status.should.be.equal false
        done()
      , 't', 'since', '2', 'weeks'

    it 'Can display the commits between two references', (done) ->
      Nock('https://api.github.com')
        .persist()
        .get("/repos/testorg/test-deployable/compare/46...47?access_token=testtoken")
        .reply(200, {
            "commits": [{
              "sha": "shaman5",
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
              "sha": "shaman5",
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
        .get('/repos/testorg/test-deployable/statuses/shaman5?access_token=testtoken')
        .reply(200, [
            {
              "state": "failure"
            }
          ])

      Changelog.action (object) ->
        object.title.should.be.equal 'Commit message from master'
        object.url.should.be.equal "https://github.com/testorg/test-deployable/commit/shaman5"
        object.comments.should.be.equal Moment("2011-01-26T19:01:12Z").fromNow()
        object.avatar.should.be.equal "lksajglkfdjg"
        object.status.should.be.equal false
        done()
      , 't', 'between', '46..47'
