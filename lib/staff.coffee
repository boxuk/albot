Configuration = require './configuration'
_ = require('underscore')._

Http = require('http')

Staff = Configuration.Staff
Commands = require './commands'
Utils = require './utils'

staff = (fallback, name) ->
  host = Staff.host
  path = "/api/search?q=#{name}"

  http = Http.get host + path, (response) ->
    response.on 'data', (chunk) ->
      body = JSON.parse(chunk.toString())
      employees = body.map (employee) -> {
          title: employee.first + employee.last
          infos: employee.role
          comments: employee.bio
          url: Staff.host + employee.html_url
          status: true
          avatar: employee.gravatar_id
        }
      
      Utils.fallback_printList(fallback, employees)

  http.on "error", (error) ->
    Utils.fallback_printError(fallback, error)

module.exports = {
  name: 'Staff',
  description: '-name- Search in a Company Staff directory and display details'
  action: staff
}

