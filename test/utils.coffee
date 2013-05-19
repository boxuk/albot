should = require('chai').should()

Utils = require '../lib/utils'

describe 'Utils', () ->
  describe '#format()', () ->
    it 'should be a string', () ->
      Utils.format().should.be.a 'string'
