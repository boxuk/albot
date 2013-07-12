Require = require('covershot').require.bind(null, require)
should = require('chai').should()

Commands = Require '../../lib/commands'
Nock = Require 'nock'

describe 'Commands', () ->
  describe '#deploy()', () ->
    before () ->
      Nock('https://api.github.com')
        .persist()
        .get('/repos/testorg/test-deployable/contents/Capfile?ref=branche&access_token=testtoken')
        .reply(200, {
            "encoding": "base64",
            "content": new Buffer("Ceci est un README").toString('base64'),
            "path": "Capfile"
          })
        .get('/repos/testorg/test-deployable/contents/app%2Fconfig%2Fdeploy.rb?ref=branche&access_token=testtoken')
        .reply(200, {
            "encoding": "base64",
            "content": new Buffer("Un fichier de configuration\nMouhahah").toString('base64'),
            "path": "app/config/deploy.rb"
          })
        .intercept('/gists/test-gist?access_token=testtoken', 'PATCH', {
          files: {
            "history": {
              content: "- PROCESSED: Ceci est un README- PROCESSED: Un fichier de configuration\nMouhahah"
            }
          }
        })
        .reply(200, {
            "html_url": "https://gist.github.com/1",
            "history": [{
              "version": "123456"
            }] 
          })
    it 'Must download files, execute the command and Gist the logs', (done) ->
      count = 1
      Commands.deploy.action (object) ->
        if count is 1
          object.title.should.be.equal 'Deploy started'
          object.infos.should.be.equal 'test-deployable'
          object.comments.should.be.equal '(branche)'
          object.status.should.be.equal true
          count += 1
        else
          object.title.should.be.equal 'Successful deploy !'
          object.url.should.be.equal 'https://gist.github.com/1/123456'
          object.infos.should.be.equal 'test-deployable'
          object.comments.should.be.equal '(branche)'
          object.status.should.be.equal true
          done()
      , 't', 'branche'
