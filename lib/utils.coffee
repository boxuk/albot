Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Styled = require 'styled'
HipchatApi = require 'hipchat'

@rooms = new HipchatApi(Nconf.get("hipchat").token).Rooms
@channel = Nconf.get("hipchat").channel
@nickname = Nconf.get("nickname")

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

  @rooms.message @channel, @nickname, format_html(title, url, infos, comments, status), {message_format: "html", color: status_color(status)}

module.exports = {
  format_term: format_term,
  format_html: format_html,
  print: print
}
