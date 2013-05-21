should = require('chai').should()

Server = require '../lib/server'

describe 'Server', () ->
  describe '#dispach()', () ->
    it 'should find the right command based on a message line', () ->
      cmd = Server.dispatch("testbot pulls")
      cmd.should.have.property('name').equal("Pull Requests")

    it 'should not dispatch for anything', () ->
      cmd = Server.dispatch("anything")
      should.not.exist cmd

    it 'should match one argument', () ->
      cmd = Server.dispatch("testbot help repository")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg1').equal("repository")

    it 'should match two arguments', () ->
      cmd = Server.dispatch("testbot help repository two")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg1').equal("repository")
      cmd.should.have.property('arg2').equal("two")

    it 'should match up to five arguments', () ->
      cmd = Server.dispatch("testbot help repository two up to five")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg1').equal("repository")
      cmd.should.have.property('arg2').equal("two")
      cmd.should.have.property('arg3').equal("up")
      cmd.should.have.property('arg4').equal("to")
      cmd.should.have.property('arg5').equal("five")
