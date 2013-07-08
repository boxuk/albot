Require = require('covershot').require.bind(null, require)

should = require('chai').should()
_ = require('underscore')._

Configuration = Require '../lib/configuration'

describe 'Configuration', () ->
  describe '#initLogger()', () ->
    it 'should initialise the global Logger', () ->
      logger = Configuration.Winston.initLogger()

      should.exist logger
      should.exist Configuration.Winston.logger
