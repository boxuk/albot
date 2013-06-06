Configuration = require './configuration'
_ = require('underscore')._

Hipchat = Configuration.Hipchat
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

format_term = (title, url, infos, comments, status, avatar) ->
  icon = status_icon(status)
  color = status_color(status)

  text = ""
  text += "#{Styled(color, icon)} " if icon? and color?
  text += "#{title}"
  text += " - #{infos}" if infos?
  text += " - #{comments}" if comments?
  text
 
format_html = (title, url, infos, comments, status, avatar) ->
  html = ""
  html += "#{status_icon(status)} "
  if (avatar?) and Configuration.Github.Gravatar
    html += "<img src='http://www.gravatar.com/avatar/#{avatar}?s=20' /> - "
  html += "<a href='#{url}'>" if url?
  html += "#{title}"
  html += "</a>" if url?
  html += " - <strong>#{infos}</strong>" if infos?
  html += " - <i>#{comments}</i>" if comments?
  html

print = (o) ->
  console.log format_term(
    o['title'],
    o['url'],
    o['infos'],
    o['comments'],
    o['status']
  )

render = (o) ->
  Hipchat.Rooms.message Hipchat.Channel,
    Configuration.Nickname,
    format_html(
      o['title'],
      o['url'],
      o['infos'],
      o['comments'],
      o['status'],
      o['avatar']
    ), {
      message_format: "html",
      color: status_color(o['status'])
    }

fallback_print = (fallback) ->
  if _.isFunction(fallback) then fallback else print

fallback_printList = (fallback, list, filter) ->
  if (_.every(list, (o) -> _.has(o, 'order')))
    list = _.sortBy(list, 'order').reverse()

  if (filter?)
    list = filter list

  _.each list, (item) ->
    fallback_print(fallback) {
      title: item.title,
      url: item.url,
      infos: item.infos,
      comments: item.comments,
      status: item.status,
      avatar: item.avatar
    }

module.exports = {
  format_term: format_term,
  format_html: format_html,
  print: print,
  render: render,
  fallback_print: fallback_print,
  fallback_printList: fallback_printList
}
