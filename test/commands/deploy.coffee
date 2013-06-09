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
            "content": "Ceci est un README",
            "path": "Capfile"
          })
        .get('/repos/testorg/test-deployable/contents/app%2Fconfig%2Fdeploy.rb?ref=branche&access_token=testtoken')
        .reply(200, {
            "encoding": "base64",
            "content": "Un fichier de configuration\nMouhahah",
            "path": "app/config/deploy.rb"
          })
        .intercept('/gists/test-gist?access_token=testtoken', 'PATCH', {
          files: {
            "history": {
              content: ".:\ntotal 8,0K\n4,0K app\n4,0K Capfile\n\n./app:\ntotal 4,0K\n4,0K config\n\n./app/config:\ntotal 4,0K\n4,0K deploy.rb\n"
            }
          }
        })
        .reply(200, {
            "html_url": "https://gist.github.com/1"
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
          object.url.should.be.equal 'https://gist.github.com/1'
          object.infos.should.be.equal 'test-deployable'
          object.comments.should.be.equal '(branche)'
          object.status.should.be.equal true
          done()
      , 't', 'branche'
