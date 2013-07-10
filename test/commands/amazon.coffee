Require = require('covershot').require.bind(null, require)

should = require('chai').should()

Configuration = Require '../../lib/configuration'
Commands = Require '../../lib/commands'

Schmock = Require 'schmock'
Moment = Require 'moment'

describe 'Commands', () ->
  describe '#amazon()', () ->
    before () ->
      Schmock.loud()
      MockAws = Schmock.mock('AmazonAws')

      MockAws.when('Route53').return {
        listHostedZones: (params, cb) ->
          cb null, { HostedZones: [
            { Id: 'hz_one' }
          ]}
        listResourceRecordSets: (params, cb) ->
          should.exist params
          params.HostedZoneId.should.equal 'hz_one'

          cb null, { ResourceRecordSets: [{
            ResourceRecords: [
              {
                Value: 'ec2-12345-dns-name.albot.com',
              }
            ], Name: 'albot.github.com'

          }, { 
            ResourceRecords: [],
            AliasTarget: { DNSName: 'dev-albot-lb-test.albot.com.' },
            Name: 'www.albot.com'
          #TODO: More than one page
          }], IsTruncated: false }
      }
      MockAws.when('EC2').return {
        describeInstances: (params, cb) ->
          cb null, { Reservations: [{
              Instances: [{
                InstanceId: 'live-albot-ec2.github.com',
                InstanceType: 'medium'
                PublicDnsName: 'ec2-12345-dns-name.albot.com',
                Tags: [{ Key: 'Name', Value: 'live-albot-1' }],
                SecurityGroups: [{ 'GroupName': 'sg-albot' }],
                IamInstanceProfile: {
                  Arn: 'blabla/live-role'
                },
                State: { Name:'running' }
              }, {
                InstanceId: 'dev-albot-ec2.github.com',
                InstanceType: 'small'
                PublicDnsName: 'ec2-6789-dns-name.albot.com',
                Tags: [{ Key: 'Name', Value: 'dev-albot-1' }],
                SecurityGroups: [{ 'GroupName': 'sg-albot' }],
                IamInstanceProfile: {
                  Arn: 'blabla/dev-role'
                },
                State: { Name:'terminated' }
              }]
            }]
          }
      }
      MockAws.when('ELB').return {
        describeLoadBalancers: (params, cb) ->
          should.exist params
          params.LoadBalancerNames[0].should.equal 'dev-albot-lb'

          cb null, { LoadBalancerDescriptions: [{
              Instances: [{ InstanceId: 'dev-albot-ec2.github.com' }],
              DNSName: 'dev-albot-lb-test.albot.com',
              LoadBalancerName: 'dev-albot-lb'
            }]
          }
      }

      Configuration.Amazon.initAws(MockAws)

    it 'should return all the instances', (done) ->
      count = 0
      Commands.amazon.action (object, cb) ->
        if (count is 0)
          object.title.should.equal "albot.github.com"
          object.url.should.equal "http://albot.github.com"
          object.infos.should.equal "live-albot-1 / medium"
          object.comments.should.equal "Security: sg-albot / Role: live-role"
          object.status.should.equal true
          should.not.exist object.avatar
          should.not.exist object.tails
        else
          object.title.should.equal "ec2-6789-dns-name.albot.com"
          object.url.should.equal "http://ec2-6789-dns-name.albot.com"
          object.infos.should.equal "dev-albot-1 / small"
          object.comments.should.equal "Security: sg-albot / Role: dev-role"
          object.status.should.equal false
          object.tails[0].should.equal "via www.albot.com - behind: dev-albot-lb"
        count += 1
        if (count is 2) then done()
        cb()
      , 'instances'

    it 'should return instances with a filter', (done) ->
      Commands.amazon.action (object, cb) ->
        object.title.should.equal "ec2-6789-dns-name.albot.com"
        object.url.should.equal "http://ec2-6789-dns-name.albot.com"
        object.infos.should.equal "dev-albot-1 / small"
        object.comments.should.equal "Security: sg-albot / Role: dev-role"
        object.status.should.equal false
        object.tails[0].should.equal "via www.albot.com - behind: dev-albot-lb"
        done()
        cb()
      , 'instances', 'with', 'www.albot.com'
