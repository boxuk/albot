should = require('chai').should()

Cache = require '../lib/cache'

describe 'Cache', () ->
  describe '#store()', () ->
    it 'should replace the cache with a new array', () ->
      array = [ "test value" ]
      Cache.store(array).should.have.length 1

  describe '#cached()', () ->
    it 'should tell if an element is in the cache', () ->
      array = [ "test value" ]
      Cache.store(array)
      Cache.cached("test value").should.equal true
