pg = require 'pg'

module.exports =
class Quest
  constructor: (host, db, user, pass, extraArgs) ->
    connString = "postgres://#{user}:#{pass}@#{host}/#{db}"
    @args = extraArgs
    @client = new pg.Client(connString)
    client.connect (err) ->
      if err
        console.error "Couldn't connect!", err
      else
        console.log "Connected!"
        @adventure
