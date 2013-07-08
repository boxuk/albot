Configuration = require './configuration'
_ = require('underscore')._

Async = require 'async'

prepareFilters = (name, value, sensitive) ->
  if (_.isString(value) or _.isArray(value))
    if (sensitive)
      value = [
        "\*" + value.toUpperCase() + "\*",
        "\*" + value.toLowerCase() + "\*"
      ]
    else if (_.isString(value))
      value = ["\*" + value + "\*"]

    {"Filters": [{
      "Name": name,
      "Values": value
    }]}

#TODO: More than 100 instances
getInstancesByParams = (Ec2, params, callback) ->
  Ec2.describeInstances params, (err, data) ->
    if (not data?)
      callback(err)
    else
      callback null, _.reduceRight data.Reservations, (memo, reservation) ->
        memo.concat(reservation.Instances)
      , []

getAllRecordSets = (Route53, callback) ->
  Route53.listHostedZones {}, (err, hostedZones) ->
    if (not hostedZones?)
      callback(err)
    else
      Async.concat hostedZones.HostedZones, (hz, cb) ->
        getAllRecordSetsAcc Route53, hz, [], null, null, cb
      , callback

getAllRecordSetsAcc = (Route53, hz, acc, recordName, recordType, callback) ->
  if (recordName? and recordType?)
    params = {"HostedZoneId": hz.Id, "StartRecordName": recordName, "StartRecordType": recordType}
  else
    params = {"HostedZoneId": hz.Id}

  Route53.listResourceRecordSets params, (err, records) ->
    if (not records?)
      callback(err, [])
    else
      all = acc.concat records.ResourceRecordSets

      if (records.IsTruncated)
        getAllRecordSetsAcc(Route53, hz, all, records.NextRecordName, records.NextRecordType, callback)
      else
        callback(null, all)

getLoadBalancersByNames = (Elb, names, callback) ->
  params = {"LoadBalancerNames": names}

  Elb.describeLoadBalancers params, (err, loadBalancers) ->
    if (not loadBalancers?)
      callback err
    else
      callback null, loadBalancers.LoadBalancerDescriptions

module.exports = {
  prepareFilters: prepareFilters,
  getInstancesByParams: getInstancesByParams,
  getAllRecordSets: getAllRecordSets,
  getLoadBalancersByNames: getLoadBalancersByNames
}
