should = require('chai').should()
_ = require('underscore')._

Commands = require '../../lib/commands'

describe 'Commands', () ->
  describe '#help()', () ->
    it 'should list the available commands', (done) ->
      count = 0
      Commands.help.action (title, url, infos, comments, status) ->
        title.should.be.a('string')
        count += 1
        if (count is _.size(Commands)) then done()
