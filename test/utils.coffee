Require = require('covershot').require.bind(null, require)

should = require('chai').should()

Utils = Require '../lib/utils'
Nock = require 'nock'

describe 'Utils', () ->
  describe '#format_term()', () ->
    it 'should have styled status', () ->
      ok = Utils.format_term("title", null, "infos", "comments", true)
      ok.should.equal "\u001b[32m✓\u001b[0m title - \u001b[1minfos\u001b[0m - \u001b[3mcomments\u001b[0m"

      nok = Utils.format_term("title", null, "infos", "comments", false)
      nok.should.equal "\u001b[31m✘\u001b[0m title - \u001b[1minfos\u001b[0m - \u001b[3mcomments\u001b[0m"

    it 'should have only title mandatory', () ->
      text = Utils.format_term("title")
      text.should.equal "\u001b[33m●\u001b[0m title"

    it 'should have tails on multi lines', () ->
      tail = ["Once", "Twice", "Thrice"]
      text = Utils.format_term("title", null, null, null, null, null, tail)
      text.should.equal "\u001b[33m●\u001b[0m title\n\t ↳ Once\n\t ↳ Twice\n\t ↳ Thrice"

  describe '#format_html()', () ->
    it 'should be nicely formatted', () ->
      ok = Utils.format_html("title", "http://google.fr", "infos", "comments", true)
      ok.should.equal "✓ <a href='http://google.fr'>title</a> - <strong>infos</strong> - <i>comments</i>"

      nok = Utils.format_html("title", "http://google.fr", "infos", "comments", false)
      nok.should.equal "✘ <a href='http://google.fr'>title</a> - <strong>infos</strong> - <i>comments</i>"

    it 'should have only title mandatory', () ->
      text = Utils.format_html("title")
      text.should.equal "● title"

    it 'should be able to display gravatars', () ->
      test = Utils.format_html("title", "http://google.fr", "infos", "comments", false, "205e460b479e2e5b48aec07710c08d50")
      test.should.equal "✘ <img src='http://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=20' /> - <a href='http://google.fr'>title</a> - <strong>infos</strong> - <i>comments</i>"

    it 'should display tails as multi-line', () ->
      test = Utils.format_html("title", null, "infos", "comments", false, null, ["this is not a tail recursion"])
      test.should.equal "✘ title - <strong>infos</strong> - <i>comments</i><br />&nbsp; ↳ this is not a tail recursion"

  describe '#render()', () ->
    it 'should send a message to the Hipchat API', () ->
      nock = Nock('http://api.hipchat.com')
        .matchHeader('Content-Type', 'application/x-www-form-urlencoded')
        .post('/v1/rooms/message?format=json&auth_token=testtoken', {
          message_format: 'html',
          color: 'yellow',
          room_id: 'testchan',
          from: 'testbot',
          message: '● test message'
        })
        .reply(200, {
          "status": "sent"
        })

      Utils.render { title: "test message" }
      nock.done()

  describe '#fallback_printList()', () ->
    it 'should handle an empty list', (done) ->
      Utils.fallback_printList (object) ->
        object.title.should.be.equal "No result for your request"
        done()
      , []
