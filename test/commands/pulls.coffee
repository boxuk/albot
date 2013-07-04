Require = require('covershot').require.bind(null, require)

should = require('chai').should()

Pulls = Require '../../lib/pulls'
Nock = Require 'nock'
Moment = Require 'moment'

describe 'Commands', () ->
  describe '#pulls()', () ->
    before () ->
      Nock('https://api.github.com')
        .persist()
        .get('/orgs/testorg/repos?page=1&per_page=100&access_token=testtoken')
        .reply(200, [
            {
              "name": "test-repo",
            }
          ])
        .get('/orgs/testorg/repos?page=2&per_page=100&access_token=testtoken')
        .reply(200, [
            {
              "name": "test-repo",
            }
        ])
        .get('/orgs/testorg/repos?page=3&per_page=100&access_token=testtoken')
        .reply(200, [])
        .get('/repos/testorg/test-repo/pulls?access_token=testtoken')
        .reply(200, [
            {
              "number": 1,
              "title": "old-feature",
              "user": {
                "login": "test-user"
              }
            },
            {
              "number": 2,
              "title": "new-feature",
              "user": {
                "login": "test-user"
              }
            }
          ])
        .get('/repos/testorg/test-repo/pulls/1?access_token=testtoken')
        .reply(200, {
              "created_at": Moment().subtract('years', 2).format(),
              "html_url": "https://github.com/octocat/Hello-World/pulls/1",
              "title": "old-feature",
              "mergeable": false,
              "state": "open",
              "comments": 50,
              "user": {
                "login": "test-user"
              },
              "head": {
                "sha": "testsha1",
                "ref": "pr-branch"
              },
              "base": {
                "ref": "master"
              }
            }
          )
        .get('/repos/testorg/test-repo/pulls/2?access_token=testtoken')
        .reply(200, {
              "created_at": Moment().subtract('months', 2).format(),
              "html_url": "https://github.com/octocat/Hello-World/pulls/2",
              "title": "new-feature",
              "mergeable": false,
              "state": "open",
              "comments": 10,
              "user": {
                "login": "test-user"
              },
              "head": {
                "sha": "testsha2",
                "ref": "pr-branch"
              },
              "base": {
                "ref": "master"
              }
            }
          )
        .get('/repos/testorg/test-repo/pulls/3?access_token=testtoken')
        .reply(200, {
              "created_at": Moment().subtract('months', 2).format(),
              "html_url": "https://github.com/octocat/Hello-World/pulls/3",
              "title": "closed-feature",
              "mergeable": false,
              "state": "closed",
              "comments": 10,
              "user": {
                "login": "test-user"
              },
              "head": {
                "sha": "testsha3",
                "ref": "pr-branch"
              },
              "base": {
                "ref": "master"
              }
            }
          )
        .get('/repos/testorg/test-repo/statuses/testsha1?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])
        .get('/repos/testorg/test-repo/statuses/testsha2?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])
        .get('/repos/testorg/test-repo/statuses/testsha3?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])

    it 'should list Pull Requests sorted by creation date', (done) ->
      count = 0
      Pulls.action (object, cb) ->
        if (count is 0)
          object.title.should.equal "new-feature"
          object.url.should.equal "https://github.com/octocat/Hello-World/pulls/2"
          object.infos.should.equal "test-repo"
          object.comments.should.equal "(pr-branch -> master) - 2 months ago - 10 comments - *NEED REBASE*"
          object.status.should.equal true
        count += 1
        if (count is 4) then done()
        cb()

    it 'should be able to resolve an URL', (done) ->
      Pulls.action (object) ->
        object.title.should.equal "closed-feature"
        object.url.should.equal "https://github.com/octocat/Hello-World/pulls/3"
        object.infos.should.equal "test-repo"
        object.comments.should.equal "(pr-branch -> master) - 2 months ago - 10 comments - *CLOSED*"
        object.status.should.equal true
        done()
      , 'https://github.com/testorg/test-repo/pull/3'

  describe '#pulls()#isRepoInFilters()', () ->
    it 'should not accept unfilterd name', () ->
      test = Pulls.isRepoInFilters("notinthelist")
      test.should.be.false

    it 'should accept any filter name', () ->
      test = Pulls.isRepoInFilters("test-repo")
      test.should.be.true

      test = Pulls.isRepoInFilters("another-one")
      test.should.be.true

  describe '#pulls()#shouldBeDisplayed()', () ->
    it 'should display normal request', () ->
      test = Pulls.shouldBeDisplayed()
      test.should.be.true

    it '-without- criteria should hide requested term', () ->
      test = Pulls.shouldBeDisplayed('without', 'stufF', 'Line with Stuff in it')
      test.should.be.false

    it '-without- criteria should display if term is not present', () ->
      test = Pulls.shouldBeDisplayed('without', 'stuff', 'Line with things in it')
      test.should.be.true

    it '-with- criteria should display if term is present', () ->
      test = Pulls.shouldBeDisplayed('with', 'stuff', 'Line with stuff')
      test.should.be.true

    it '-with- criteria should hide if term is not present', () ->
      test = Pulls.shouldBeDisplayed('with', 'stuff', 'Line with things')
      test.should.be.false

    it '-recent- criteria should hide older than a week', () ->
      older = Moment().subtract('weeks', 3)
      test = Pulls.shouldBeDisplayed('recent', undefined, 'Line with things', older)
      test.should.be.false

    it '-recent- criteria should show younger than a week', () ->
      younger = Moment().subtract('days', 1)
      test = Pulls.shouldBeDisplayed('recent', undefined, 'Line with things', younger)
      test.should.be.true

    it '-recent- criteria should hide older than a month', () ->
      older = Moment().subtract('months', 5)
      test = Pulls.shouldBeDisplayed('recent', 'months', 'Line with things', older)
      test.should.be.false

    it '-last- alongside a criteria should act like -with-', () ->
      test = Pulls.shouldBeDisplayed('last', 'stuff', 'Line with stuff')
      test.should.be.true

      test = Pulls.shouldBeDisplayed('last', 'stuff', 'Line with things')
      test.should.be.false

    it '-last- alone should display', () ->
      test = Pulls.shouldBeDisplayed('last', undefined, 'Line with stuff')
      test.should.be.true

    it '-last- with a number should display', () ->
      test = Pulls.shouldBeDisplayed('last', '5', 'Line with stuff')
      test.should.be.true

    it 'should display if criteria unknown', () ->
      test = Pulls.shouldBeDisplayed('truc', 'stuff', 'Line with things in it')
      test.should.be.true

    it 'should display if term is null', () ->
      test = Pulls.shouldBeDisplayed('without', undefined, 'Line with stuff')
      test.should.be.true

  describe '#pulls()#pickLastIfNeeded()', () ->
    list = ['stuff', 'things', 'truc', 'machin']

    it 'should return the list if not -last-', () ->
      test = Pulls.pickLastIfNeeded(undefined, undefined, list)
      test.should.be.list

    it '-last- should return the first one', () ->
      test = Pulls.pickLastIfNeeded('last', undefined, list)
      test.should.have.length 1
      test.should.include 'stuff'

    it '-last name- should return the first one', () ->
      test = Pulls.pickLastIfNeeded('last', 'name', list)
      test.should.have.length 1
      test.should.include 'stuff'

    it '-last 3- should return the first three', () ->
      test = Pulls.pickLastIfNeeded('last', '3', list)
      test.should.have.length 3
      test.should.include 'stuff'
      test.should.include 'things'
      test.should.include 'truc'
