Require = require('covershot').require.bind(null, require)

should = require('chai').should()
Nock = require 'nock'

Configuration = Require '../lib/configuration'
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

    it 'should not answer to himself', () ->
      cmd = Server.dispatch("albot pulls", "#{Configuration.Nickname}")
      should.not.exist cmd

    it 'should match one argument', () ->
      cmd = Server.dispatch("testbot help repository")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.deep.property('args[0]').equal("repository")

    it 'should match arguments with upper cases', () ->
      cmd = Server.dispatch("testbot help Repository")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.deep.property('args[0]').equal("Repository")
      cmd.should.not.have.deep.property('args[1]')

    it 'should match arguments with some special characters', () ->
      cmd = Server.dispatch("testbot help -Do+not.merge_:")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.deep.property('args[0]').equal("-Do+not.merge_:")

    it 'should match url', () ->
      cmd = Server.dispatch("testbot help http://github.com/testing")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.deep.property('args[0]').equal("http://github.com/testing")

    it 'should match arguments with numbers', () ->
      cmd = Server.dispatch("testbot help 24")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.deep.property('args[0]').equal("24")

    it 'should match two arguments', () ->
      cmd = Server.dispatch("testbot help repository two")
      cmd.should.have.property('name').equal("Help")
      cmd.should.have.deep.property('args[0]').equal("repository")
      cmd.should.have.deep.property('args[1]').equal("two")

    it 'should match up to five arguments', () ->
      cmd = Server.dispatch("testbot help repository two up to five")
      cmd.should.have.deep.property('name').equal("Help")
      cmd.should.have.deep.property('args[0]').equal("repository")
      cmd.should.have.deep.property('args[1]').equal("two")
      cmd.should.have.deep.property('args[2]').equal("up")
      cmd.should.have.deep.property('args[3]').equal("to")
      cmd.should.have.deep.property('args[4]').equal("five")

    it 'should match PR url anywhere in a message', () ->
      cmd = Server.dispatch("PR: https://github.com/me/albot/pull/25 https://github.com/you/albot/pull/42")
      cmd.should.have.property('name').equal("Pull Requests")
      cmd.should.have.deep.property('args[0]').equal("PR: https://github.com/me/albot/pull/25 https://github.com/you/albot/pull/42")

    it 'should match an Issue url anywhere in a message', () ->
      cmd = Server.dispatch("Issue: https://thieriotandco.atlassian.net/browse/ALB-94")
      cmd.should.have.property('name').equal("Issues")
      cmd.should.have.deep.property('args[0]').equal("Issue: https://thieriotandco.atlassian.net/browse/ALB-94")
