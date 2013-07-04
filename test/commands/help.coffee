Require = require('covershot').require.bind(null, require)

should = require('chai').should()
_ = require('underscore')._

Commands = Require '../../lib/commands'

describe 'Commands', () ->
  describe '#help()', () ->
    it 'should list the available commands (non-ommitted)', (done) ->
      count = 0
      Commands.help.action (object) ->
        object.title.should.be.a('string')
        object.title.should.not.equal('Pulls')
        count += 1
        if (count is parseInt(_.size(Commands)) - 1) then done()
