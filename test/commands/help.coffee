Require = require('covershot').require.bind(null, require)

should = require('chai').should()
_ = require('underscore')._

Commands = Require '../../lib/commands'

describe 'Commands', () ->
  describe '#help()', () ->
    it 'should list the available commands', (done) ->
      count = 0
      Commands.help.action (object) ->
        object.title.should.be.a('string')
        count += 1
        if (count is _.size(Commands)) then done()
