Require = require('covershot').require.bind(null, require)

should = require('chai').should()

AwsHelpers = Require '../lib/aws_helpers'

describe 'AwsHelpers', () ->
  describe '#prepareFilters()', () ->
    it 'should prepare the right Filters for String', () ->
      filters = AwsHelpers.prepareFilters 'tag:Name', 'dev-albot-1'
      filters.Filters[0].Name.should.equal 'tag:Name'
      filters.Filters[0].Values[0].should.equal '*dev-albot-1*'

    it 'should prepare the right Filters for String and case sensitive', () ->
      filters = AwsHelpers.prepareFilters 'tag:Name', 'dev-albot-2', true
      filters.Filters[0].Name.should.equal 'tag:Name'
      filters.Filters[0].Values[0].should.equal '*DEV-ALBOT-2*'
      filters.Filters[0].Values[1].should.equal '*dev-albot-2*'

    it 'should prepare the right Filters for Array', () ->
      filters = AwsHelpers.prepareFilters 'tag:Name', ['dev-albot-3']
      filters.Filters[0].Name.should.equal 'tag:Name'
      filters.Filters[0].Values[0].should.equal 'dev-albot-3'
