Sync = require 'sync'
fs = require 'fs'
path = require 'path'
pg = require 'pg'
colors = require 'colors'
Mustache = require 'mustache'

module.exports =
class Quest
  constructor: (host, db, user, pass, @time, extraArgs) ->
    @questDir = path.dirname module.parent.filename
    connString = "postgres://#{user}:#{pass}@#{host}/#{db}"
    @args = extraArgs
    @client = new pg.Client(connString)
    @client.connect (err) =>
      if err
        console.error "Couldn't connect!".red.bold
        console.error err.message.red
      else
        Sync (=> @adventure()), (err, result) =>
          @client.end()
          if err
            console.error "An error occurred!".red.bold
            console.error err.message.red.underline

  transaction: (cb) ->
    console.log "Beginning transaction\n".blue.underline
    @sql "BEGIN;"
    try
      cb()
    catch e
      console.error "An error occurred, rolling back\n".red.underline
      @sql "ROLLBACK;"
      throw e
    @sql """-- Ending transaction!
            COMMIT;"""

  retry: (opts, cb) ->
    if typeof(opts) != 'function'
      {times, wait, okErrors} = opts
    else
      cb = opts
      opts = {}
    wait ?= 5000
    times ?= 10
    while true
      try
        return cb()
      catch e
        if not okErrors? or okErrors.some((regex) -> e.message.match regex)
          if times == 'forever' or times > 0
            console.error "Error occurred: #{e.message}".red.underline
            console.log "Retrying in #{wait}ms. Retries left: #{times}".red.bold
            console.log()
            Sync.sleep(wait)
            times -= 1
          else
            console.error "Out of lives... I give up.\n".red.underline
            throw e

  sql: (queries, view={}, cb) ->
    if typeof(queries) != 'string'
      sqlPath = path.join @questDir, 'sql', queries.file
      console.log ">>".blue.bold, "#{sqlPath}".blue.bold
      queries = fs.readFileSync(sqlPath, encoding: 'utf-8')
    queries = Mustache.render queries, view
      .split ';'
      .map (s) -> s.trim()
      .filter (s) -> s
    result = null
    for _, query of queries
      console.log "#{query};".green
      if cb?
        @client.query(query, cb)
      else
        console.time('Execution time') if @time
        result = @client.query.sync(@client, query)
        if @time
          console.timeEnd('Execution time')
      console.log()
    result
