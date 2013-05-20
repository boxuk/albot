should = require('chai').should()

Commands = require '../../lib/commands'
Nock = require 'nock'

describe 'Commands', () ->
  describe '#pulls()', () ->
    before () ->
      Nock('https://api.github.com')
        .get('/orgs/testorg/repos?per_page=100&access_token=testtoken')
        .reply(200, [
            {
              "name": "test-repo",
            }
          ])
        .get('/repos/testorg/test-repo/pulls?access_token=testtoken')
        .reply(200, [
            {
              "number": 1,
            }
          ])
        .get('/repos/testorg/test-repo/pulls/1?access_token=testtoken')
        .reply(200, {
              "html_url": "https://github.com/octocat/Hello-World/pulls/1",
              "title": "new-feature",
              "mergeable": true,
              "comments": 10,
            }
          )

    it 'should list Pull Requests', (done) ->
      Commands.pulls.action (title, url, infos, comments, status) ->
        title.should.equal "new-feature"
        url.should.equal "https://github.com/octocat/Hello-World/pulls/1"
        infos.should.equal "test-repo"
        comments.should.equal "10 comments"
        status.should.equal true
        done()
