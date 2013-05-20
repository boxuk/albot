Configuration = require '../lib/configuration'

should = require('chai').should()

Server = require '../lib/server'

describe 'Server', () ->
  describe '#dispach()', () ->
    it 'should find the right command based on a message line', () ->
      cmd = Server.dispatch("#{Configuration.get("nickname")} pulls")
      cmd.should.have.property('name').equal("Pull Requests")

    it 'should not dispatch for anything', () ->
      cmd = Server.dispatch("anything")
      should.not.exist cmd

    it 'should match argument', () ->
      cmd = Server.dispatch("#{Configuration.get("nickname")} help repository")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg').equal("repository")
