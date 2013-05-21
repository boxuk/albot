Configuration = require './configuration'

Styled = require 'styled'
_ = require('underscore')._
HipchatApi = require 'hipchat'

@rooms = new HipchatApi(Configuration.get("hipchat").token).Rooms
@channel = Configuration.get("hipchat").channel
@nickname = Configuration.get("nickname")

status_icon = (status) -> if status then "✓" else "✘"
status_color = (status) -> 
  if (status?)
    if status then "green" else "red"
  else
    "yellow"

format_term = (title, url, infos, comments, status) ->
  icon = status_icon(status)
  color = status_color(status)

  text = ""
  text += "#{Styled(color, icon)} " if status? and icon? and color?
  text += "#{title}"
  text += " - #{infos}" if infos?
  text += " - #{comments}" if comments?
  text
 
format_html = (title, url, infos, comments, status) ->
  html = ""
  html += "#{status_icon(status)} " if status?
  html += "<a href='#{url}'>" if url?
  html += "#{title}"
  html += "</a>" if url?
  html += " - <strong>#{infos}</strong>" if infos?
  html += " - <i>#{comments}</i>" if comments?
  html

print = (title, url, infos, comments, status) =>
  console.log format_term(title, url, infos, comments, status)

render = (title, url, infos, comments, status) =>
  @rooms.message @channel, @nickname, format_html(title, url, infos, comments, status), {message_format: "html", color: status_color(status)}

printWithFallback = (fallback) ->
  if _.isFunction(fallback) then fallback else print

module.exports = {
  format_term: format_term,
  format_html: format_html,
  print: print,
  render: render,
  printWithFallback: printWithFallback
}
