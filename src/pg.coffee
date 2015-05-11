
pg = require('pg').native
Sync = require 'sync'
read = require 'read'

module.exports =

  # Private: Create a pg client from a URL or host, port, db, user, and pass.
  #
  # * `url`: A postgres:// url to connect to.
  # OR
  # * `host`: {String} hostname to connect to.
  # * `port`: {Number} port to connect with.
  # * `db`: {String} db to connect to.
  # * `user`: {String} username to connect with.
  # * `pass`: {String} password to connect with.
  #
  # Returns a {pg.Client}.
  createClient: (host, port, db, user, pass) ->
    if arguments.length > 1
      unless pass
        try
          pass = read.sync null, prompt: "Password:", silent: true
        catch e
          throw new Error("A password is required to venture forth!")
      new pg.Client "postgres://#{user}:#{pass}@#{host}:#{port}/#{db}"
    else
      new pg.Client host # Actually url.


  connect: (client, cb) ->
    client.connect (err) =>
      if err
        console.error "Couldn't connect with PG!".red.bold
        console.error err.message.red
        console.error err.stack.red
        cb(err)
      else
        cb(null, client)
