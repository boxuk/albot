Require = require('covershot').require.bind(null, require)

should = require('chai').should()

Commands = Require '../../lib/commands'
Nock = Require 'nock'
Moment = Require 'moment'

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
              "created_at": Moment().subtract('years', 2).format(),
              "html_url": "https://github.com/octocat/Hello-World/pulls/1",
              "title": "new-feature",
              "mergeable": false,
              "comments": 10,
              "user": {
                "login": "test-user"
              },
              "head": {
                "sha": "testsha"
              }
            }
          )
        .get('/repos/testorg/test-repo/statuses/testsha?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])

    it 'should list Pull Requests', (done) ->
      Commands.pulls.action (title, url, infos, comments, status) ->
        console.log(comments)
        title.should.equal "new-feature"
        url.should.equal "https://github.com/octocat/Hello-World/pulls/1"
        infos.should.equal "test-repo"
        comments.should.equal "2 years ago - 10 comments - *NEED REBASE*"
        status.should.equal true
        done()

  describe '#pulls()#isRepoInFilters()', () ->
    it 'should not accept unfilterd name', () ->
      test = Commands.pulls.isRepoInFilters("notinthelist")
      test.should.be.false

    it 'should accept any filter name', () ->
      test = Commands.pulls.isRepoInFilters("test-repo")
      test.should.be.true

      test = Commands.pulls.isRepoInFilters("another-one")
      test.should.be.true

  describe '#pulls()#shouldBeDisplayed()', () ->
    it 'should display normal request', () ->
      test = Commands.pulls.shouldBeDisplayed()
      test.should.be.true

    it '-without- criteria should hide requested term', () ->
      test = Commands.pulls.shouldBeDisplayed('without', 'stufF', 'Line with Stuff in it')
      test.should.be.false

    it '-without- criteria should display if term is not present', () ->
      test = Commands.pulls.shouldBeDisplayed('without', 'stuff', 'Line with things in it')
      test.should.be.true

    it '-with- criteria should display if term is present', () ->
      test = Commands.pulls.shouldBeDisplayed('with', 'stuff', 'Line with stuff')
      test.should.be.true

    it '-with- criteria should hide if term is not present', () ->
      test = Commands.pulls.shouldBeDisplayed('with', 'stuff', 'Line with things')
      test.should.be.false

    it '-recent- criteria should hide older than a week', () ->
      older = Moment().subtract('weeks', 3)
      test = Commands.pulls.shouldBeDisplayed('recent', undefined, 'Line with things', older)
      test.should.be.false

    it '-recent- criteria should show younger than a week', () ->
      younger = Moment().subtract('days', 1)
      test = Commands.pulls.shouldBeDisplayed('recent', undefined, 'Line with things', younger)
      test.should.be.true

    it '-recent- criteria should hide older than a month', () ->
      older = Moment().subtract('months', 5)
      test = Commands.pulls.shouldBeDisplayed('recent', 'months', 'Line with things', older)
      test.should.be.false

    it 'should display if criteria unknown', () ->
      test = Commands.pulls.shouldBeDisplayed('truc', 'stuff', 'Line with things in it')
      test.should.be.true

    it 'should display if term is null', () ->
      test = Commands.pulls.shouldBeDisplayed('without', undefined, 'Line with stuff')
      test.should.be.true
