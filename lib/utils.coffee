Nconf = require 'nconf'
Nconf.env().file({file: '.albot.json'})

Styled = require 'styled'
HipchatApi = require 'hipchat'

@rooms = new HipchatApi(Nconf.get("hipchat").token).Rooms
@channel = Nconf.get("hipchat").channel
@nickname = Nconf.get("nickname")

display = (status, title, url, infos, comments) =>
  iconCmd = if status then Styled.green('✓') else Styled.red('✘')
  icon = if status then "✓" else "✘"
  statusColor = if status then "green" else "red"

  console.log "#{iconCmd} #{title} - #{infos} - #{comments} comments"
  @rooms.message(@channel, @nickname, "#{icon} <a href='#{url}'>#{title}</a>: <strong>#{infos}</strong> - <i>#{comments} comments</i>", {message_format: "html", color: statusColor})

module.exports = {
  display: display
}
