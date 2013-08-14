Configuration = require './configuration'
_ = require('underscore')._

Hipchat = Configuration.Hipchat
Async = require 'async'
Styled = require 'styled'

status_icon = (status) ->
  if (status?)
    if status then "✓" else "✘"
  else
    "●"

status_color = (status) ->
  if (status?)
    if status then "green" else "red"
  else
    "yellow"

format_term = (title, url, infos, comments, status, avatar, tails) ->
  icon = status_icon(status)
  color = status_color(status)

  text = ""
  text += "#{Styled(color, icon)} " if icon? and color?
  text += "#{title}"
  text += " - #{Styled('bold', infos)}" if infos?
  text += " - #{Styled('italic', comments)}" if comments?
  if (tails?)
    for tail in tails
      do (tail) ->
        text += "\n\t ↳ #{tail}"

  text

# TODO: Use templating
format_html = (title, url, infos, comments, status, avatar, tails) ->
  html = ""
  html += "#{status_icon(status)} "
  if (avatar?) and Configuration.Github.Gravatar
    if (avatar.indexOf('http') > -1)
      html += "<img src='#{avatar}' height='20px' width='20px' /> - "
    else
      html += "<img src='http://www.gravatar.com/avatar/#{avatar}?s=20' /> - "
  html += "<a href='#{url}'>" if url?
  html += "#{title}"
  html += "</a>" if url?
  html += " - <strong>#{infos}</strong>" if infos?
  html += " - <i>#{comments}</i>" if comments?
  if (tails?)
    for tail in tails
      do (tail) ->
        html += "<br />&nbsp; ↳ #{tail}"

  html

print = (o, callback) ->
  console.log format_term(
    o['title'],
    o['url'],
    o['infos'],
    o['comments'],
    o['status']
    o['avatar']
    o['tails']
  )
  if (callback? and _.isFunction(callback)) then callback(null)

render = (o, callback) ->
  Hipchat.Rooms.message Hipchat.Channel,
    Configuration.Nickname,
    format_html(
      o['title'],
      o['url'],
      o['infos'],
      o['comments'],
      o['status'],
      o['avatar']
      o['tails']
    ), {
      message_format: "html",
      color: status_color(o['status'])
    }, (error) ->
      if (callback? and _.isFunction(callback)) then callback(error)

fallback_print = (fallback) ->
  if fallback? and _.isFunction(fallback) then fallback else print

fallback_printList = (fallback, list, filter) ->
  if (_.isEmpty(list))
    fallback_print(fallback) { title: "No result for your request" }

  if (_.every(list, (o) -> _.has(o, 'order')))
    list = _.sortBy(list, 'order').reverse()

  if (filter?)
    list = filter list

  Async.eachSeries list, (item, callback) ->
    fallback_print(fallback) {
      title: item.title,
      url: item.url,
      infos: item.infos,
      comments: item.comments,
      status: item.status,
      avatar: item.avatar,
      tails: item.tails
    }, callback
  , (error) ->
    if (error?)
      print { title: "An error occured while sending a message: #{JSON.stringify(error)}", status: false }

fallback_printError = (fallback, error) ->
  fallback_print(fallback) { title: "An error occured: #{JSON.stringify(error)}", status: false }

module.exports = {
  format_term: format_term,
  format_html: format_html,
  print: print,
  render: render,
  fallback_print: fallback_print,
  fallback_printList: fallback_printList,
  fallback_printError: fallback_printError
}
