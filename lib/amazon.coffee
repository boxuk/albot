Configuration = require './configuration'
_ = require('underscore')._
_.str = require 'underscore.string'
_.mixin _.str.exports()

Async = require 'async'

Utils = require './utils'
AwsHelpers = require './aws_helpers'

amazon = (fallback, keyword, filter, filterValue) ->

  Route53 = new Configuration.Amazon.aws.Route53()
  Ec2 = new Configuration.Amazon.aws.EC2()
  Elb = new Configuration.Amazon.aws.ELB()

  params = {}

  if (keyword == 'instances')
    AwsHelpers.getAllRecordSets Route53, (err, recordSets) ->
      if (not recordSets?)
        Utils.fallback_printError fallback, err
      else
        dnsRoutePairs = mappingDnsWithRoute(recordSets)

        findInstancesBehindLoadBalancer Elb, dnsRoutePairs, (err, idInstances) ->
          if (not idInstances?)
            Utils.fallback_printError fallback, err
          else
            if (filter == 'with')
              display fallback, Ec2, params, dnsRoutePairs, idInstances, filterValue
            else
              display fallback, Ec2, params, dnsRoutePairs, idInstances, filter


display = (fallback, Ec2, params, dnsRoutePairs, idInstances, filterValue) ->
  AwsHelpers.getInstancesByParams Ec2, params, (err, results) ->
    list = _.map results, (instance) ->

      tag = _.findWhere instance.Tags, {"Key": "Name"}
      security = instance.SecurityGroups[0]
      role = if instance.IamInstanceProfile? then " / Role: " + instance.IamInstanceProfile.Arn.split('/')[1] else ""
      route = _.findWhere dnsRoutePairs, {"Dns": instance.PublicDnsName}
      title =
        if (route?)
          route.Route
        else if instance.PublicDnsName
          instance.PublicDnsName
        else
          "No route or public dns"

      behinds = _.findWhere idInstances, {"Id": instance.InstanceId}
      lb = if behinds? and behinds.LoadBalancer? then " - behind: #{behinds.LoadBalancer.LoadBalancerName}" else ""

      {
        title: title
        #TODO: Should remove the trailing dot
        url: "http://#{title}"
        infos: if tag? then tag.Value + ' / ' + instance.InstanceType else instance.InstanceType
        comments: if security? then "Security: #{security.GroupName}#{role}"
        status: instance.State.Name == 'running'
        tails: if behinds? then _.map _.pluck(behinds.Routes, 'Route'), (route) -> "via #{route}#{lb}"
      }

    Utils.fallback_printList fallback, list, (list) ->
      if (filterValue?)
        _.filter list, (o) ->
          stuff = o.title + o.infos + o.comments
          stuff += _.reduce o.tails, (memo, tail) ->
            memo.concat(tail)
          , []

          _.str.include(stuff, filterValue)
      else
        list

mappingDnsWithRoute = (recordSets) ->
  _.reduce recordSets, (memo, recordSet) ->
    if (not _.isEmpty(recordSet.ResourceRecords))
      memo.concat _.map recordSet.ResourceRecords, (record) ->
        { Dns: record.Value, Route: recordSet.Name }
    else
      memo.concat [
        { Dns: recordSet.AliasTarget.DNSName, Route: recordSet.Name }
      ]
  , []

findInstancesBehindLoadBalancer = (Elb, routes, callback) ->
  names = _.reduce routes, (memo, dnsRoutePair) ->
    match = dnsRoutePair.Dns.match("^(.*lb)-")

    if match then memo.concat(match[1]) else memo
  , []

  AwsHelpers.getLoadBalancersByNames Elb, _.uniq(names), (err, lbDescriptions) ->
    if (not lbDescriptions?)
      callback err
    else
      Async.reduce lbDescriptions, [], (memo, description, cb) ->
        cb null, memo.concat _.map description.Instances, (instance) ->
          {
            Id: instance.InstanceId,
            LoadBalancer: description,
            Routes: _.where(routes, {"Dns": description.DNSName + "."})
          }
      , (err, idInstances) ->
        callback null, idInstances

module.exports = {
  name: "Amazon",
  description: "[ instances [ with -term- ] ] Display various informations about your Amazon infrastructure",
  action: amazon
}
