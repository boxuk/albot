Require = require('covershot').require.bind(null, require)

should = require('chai').should()

Commands = Require '../../lib/commands'
Nock = Require 'nock'
Moment = Require 'moment'

describe 'Commands', () ->
  describe '#issues()', () ->
    before () ->
      Nock('https://thieriotandco.atlassian.net')
        .persist()
        .get('/rest/api/2/issue/alb-100')
        .reply(200, {
            "key": "ALB-100",
            "fields": {
              "summary": "I'm a teapot",
              "project": { "name": "Albot" },
              "issuetype": { "name": "Feature" },
              "status": { "name": "Open" },
              "sp": 13,
              "comment": { "total": 2 },
              "priority": { "name": "URGENT" },
              "assignee": {
                "avatarUrls": { "24x24": "http://my.avatar.com" }
              },
              "description": "Awesome feature"
            }
          })
        .get('/rest/api/2/issue/alb-200')
        .reply(200, {
            "key": "ALB-200",
            "fields": {
              "summary": "I'm a super task",
              "project": { "name": "Albot" },
              "issuetype": { "name": "Feature" },
              "status": { "name": "Open" },
              "sp": 13,
              "comment": { "total": 0 },
              "priority": { "name": "MAJOR" },
              "subtasks": [
                { "key": "ALB-201" },
                { "key": "i-m-not-a-teapot" },
              ]
            }
          })
        .get('/rest/api/2/issue/alb-201')
        .reply(200, {
            "key": "ALB-201",
            "fields": {
              "summary": "I'm a sub task",
              "project": { "name": "Albot" },
              "issuetype": { "name": "Subtask" },
              "status": { "name": "In progress" },
              "comment": { "total": 0 },
              "priority": { "name": "MAJOR" }
            }
          })
        .get('/rest/api/2/issue/i-m-not-a-teapot')
        .reply(404, {
          "Invalid issue number."
        })

    it 'should display an issue details', (done) ->
      Commands.issues.action (object, cb) ->
        object.title.should.equal "I'm a teapot"
        object.url.should.equal "https://thieriotandco.atlassian.net/browse/ALB-100"
        object.infos.should.equal "Albot: Feature(13)"
        object.comments.should.equal "2 comments - *URGENT*"
        object.status.should.equal false
        object.avatar.should.equal "http://my.avatar.com"
        object.tails[0].should.equal "Awesome feature"
        done()
      , 'alb-100'

    it 'should parse  an issue URL', (done) ->
      Commands.issues.action (object, cb) ->
        object.title.should.equal "I'm a teapot"
        object.url.should.equal "https://thieriotandco.atlassian.net/browse/ALB-100"
        object.infos.should.equal "Albot: Feature(13)"
        object.comments.should.equal "2 comments - *URGENT*"
        object.status.should.equal false
        object.avatar.should.equal "http://my.avatar.com"
        object.tails[0].should.equal "Awesome feature"
        done()
      , 'https://thieriotandco.atlassian.net/browse/ALB-100'

    it 'should handle bad requests', (done) ->
      Commands.issues.action (object, cb) ->
        object.title.should.equal "An error occured: \"Invalid issue number.\""
        object.status.should.equal false
        done()
      , 'I-m-not-a-teapot'

    it 'should display subtasks if available', (done) ->
      count = 0
      Commands.issues.action (object, cb) ->
        count += 1
        if (count == 1)
          object.title.should.equal "I'm a super task"
          object.url.should.equal "https://thieriotandco.atlassian.net/browse/ALB-200"
          object.infos.should.equal "Albot: Feature(13)"
          object.comments.should.equal "0 comments - *MAJOR*"
          object.status.should.equal false
          cb()
        else
          object.title.should.equal "I'm a sub task"
          object.url.should.equal "https://thieriotandco.atlassian.net/browse/ALB-201"
          object.infos.should.equal "Albot: Subtask"
          object.comments.should.equal "0 comments - *MAJOR*"
          should.not.exist object.status
          done()
      , 'alb-200'

  describe '#issues()#resolveStatus()', () ->
   it 'should detect Open status as not ok', () ->
     st = Commands.issues.resolveStatus({"name": "Open"})
     st.should.equal false

   it 'should detect Closed status as ok', () ->
     st = Commands.issues.resolveStatus({"name": "Closed"})
     st.should.equal true

   it 'should detect anything else as in progress', () ->
     st = Commands.issues.resolveStatus({"name": "Ready for QA"})
     should.not.exist st

     st = Commands.issues.resolveStatus()
     should.not.exist st

     st = Commands.issues.resolveStatus({name: ""})
     should.not.exist st
