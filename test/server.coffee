Require = require('covershot').require.bind(null, require)

should = require('chai').should()
Nock = require 'nock'

Server = Require '../lib/server'

describe 'Server', () ->
  describe '#action()', () ->
    it 'should detect only new commands', (done) ->
      count = 0

      Nock('http://api.hipchat.com')
        .persist()
        .filteringRequestBody(/.*/, '*')
        .get('/v1/rooms/history?format=json&auth_token=testtoken&room_id=testchan&date=recent')
        .reply 200, (uri, requestBody) ->
          count += 1
          if (count is 1)
            {
              "messages": [
                {
                  "date": "2010-11-19T15:48:19-0800",
                  "from": {
                    "name": "Garret Heaton",
                    "user_id": 10
                  },
                  "message": "testbot pulls"
                }
              ]
            }
          else
            {
              "messages": [
                {
                  "date": "2010-11-19T15:48:19-0800",
                  "from": {
                    "name": "Garret Heaton",
                    "user_id": 10
                  },
                  "message": "testbot pulls"
                },
                {
                  "date": "2010-11-19T15:48:19-0800",
                  "from": {
                    "name": "Garret Heaton",
                    "user_id": 10
                  },
                  "message": "testbot help"
                }
              ]
            }

      Server.action '10', (id, cmd) ->
        clearInterval(id)
        cmd.name.should.equal 'Help'
        done()

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

    it 'should match arguments with upper cases', () ->
      cmd = Server.dispatch("testbot help Repository")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg1').equal("Repository")
      cmd.should.not.have.property('arg2')

    it 'should match arguments with some special characters', () ->
      cmd = Server.dispatch("testbot help Do+not-merge")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg1').equal("Do+not-merge")

    it 'should match url', () ->
      cmd = Server.dispatch("testbot help http://github.com/testing")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg1').equal("http://github.com/testing")

    it 'should match arguments with numbers', () ->
      cmd = Server.dispatch("testbot help 24")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.property('arg1').equal("24")

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
