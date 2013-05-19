Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Styled = require 'styled'
HipchatApi = require 'hipchat'

@rooms = new HipchatApi(Nconf.get("hipchat_token")).Rooms

display = (status, title, url, infos, comments) =>
  iconCmd = if status then Styled.green('✓') else Styled.red('✘')
  icon = if status then "✓" else "✘"
  statusColor = if status then "green" else "red"

  console.log "#{iconCmd} #{title} - #{infos} - #{comments} comments"
  @rooms.message("albot", "bot", "#{icon} <a href='#{url}'>#{title}</a>: <strong>#{infos}</strong> - <i>#{comments} comments</i>", {message_format: "html", color: statusColor})

module.exports = {
  display: display
}
