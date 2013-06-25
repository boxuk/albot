Require = require('covershot').require.bind(null, require)

should = require('chai').should()

GhHelpers = Require '../lib/gh_helpers'

describe 'GhHelpers', () ->
  describe '#buildStatus()', () ->
    it 'should be true if success', () ->
      statuses = GhHelpers.buildStatus [{
        "state": "success"
      }]
      statuses.should.be.equal true

    it 'should be undefined if pending', () ->
      statuses = GhHelpers.buildStatus [{
        "state": "pending"
      }]
      should.not.exist statuses

    it 'should be undefined if undefined', () ->
      statuses = GhHelpers.buildStatus [{}]
      should.not.exist statuses

    it 'should be false if error', () ->
      statuses = GhHelpers.buildStatus [{
        "state": "error"
      }]
      statuses.should.be.equal false

    it 'should be false if failure', () ->
      statuses = GhHelpers.buildStatus [{
        "state": "failure"
      }]
      statuses.should.be.equal false

describe 'GhHelpers', () ->
  describe '#githubPRUrlMatching:()', () ->
    it 'should match parts of a PR url', () ->
      url = "https://github.com/boxuk/albot/pull/7"
      match = GhHelpers.githubPRUrlMatching(url)
      match.org.should.be.equal "boxuk"
      match.repo.should.be.equal "albot"
      match.number.should.be.equal "7"
