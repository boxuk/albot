should = require('chai').should()

Utils = require '../lib/utils'

describe 'Utils', () ->
  describe '#format_term()', () ->
    it 'should have styled status', () ->
      ok = Utils.format_term("title", null, "infos", "comments", true)
      ok.should.equal "\u001b[32m✓\u001b[0m title - infos - comments"

      nok = Utils.format_term("title", null, "infos", "comments", false)
      nok.should.equal "\u001b[31m✘\u001b[0m title - infos - comments"

    it 'should have only title mandatory', () ->
      text = Utils.format_term("title")
      text.should.equal "\u001b[33m●\u001b[0m title"

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
