# Questing library! Everything you need for your adventure. It isn't
# safe to go alone.
Sync = require 'sync'
fs = require 'fs'
path = require 'path'
pg = require 'pg'
colors = require 'colors'
Mustache = require 'mustache'

module.exports =

# Public: Base quest class.
#
# {Quest} is the important part of the equation. Its methods make up the DSL
# that makes sqlquest special and powerful. Extend this class and implement the
# {{Quest::adventure}} method to create a quest. # When a subclass of {Quest} is
# instantiated, it runs its {{Quest::adventure}} method inside of a fiber with
# [node-sync](https://github.com/ybogdanov/node-sync). The provided methods are
# synchronous by default, and this is a core part of what makes the {Quest} DSL
# powerful. {{Quest::sql}} can take a callback, but by default it executes
# queries synchronous so that you can author your SQL quests (jobs) in a clean,
# easy, readable way.
#
# ## Examples
#
# The simplest example is a completely blank implementation
#
# ```coffee
# class AwesomeQuest extends Quest
# ```
#
# This will cause sqlquest to simply look for a `quests/awesome/sql/awesome.sql`
# file and run it with {{Quest::sql}}. This covers the most trivial usecases.
# For more advanced usage where you want to embed sql, deal with results of
# queries, run multiple files, do retries, etc, you'll want to implement
# {{Quest::adventure}}.
#
# ```coffee
# class AwesomeQuest extends Quest
#   adventure: ->
#     @sql """SELECT * FROM foo
#             WHERE athing > anotherthing"""
#     @sql file: "lol.sql"
#     @sql "SELECT * from {{table}}", table: 'atablename'
# ```
#
# See {{Quest::sql}} for a detailed description of what is possible.
class Quest

  # Private: Construct a quest instance.
  #
  # * `host`: {String} Hostname of the database.
  # * `db`: {String} Name of the database.
  # * `user`: {String} Database user.
  # * `pass`: {String} Database password.
  # * `time`: {Boolean} Set to false to not print execution time of each quury.
  # * `name`: {String} Quest name (same as passed on the command line).
  # * `opts`: {Object} Parsed command line args for the quest.
  constructor: (host, db, user, pass, @time, @name, @opts) ->
    @questDir = path.dirname module.parent.filename
    connString = "postgres://#{user}:#{pass}@#{host}/#{db}"
    @client = new pg.Client(connString)
    @client.connect (err) =>
      if err
        console.error "Couldn't connect!".red.bold
        console.error err.message.red
      else
        @adventure ?= => @sql file: "#{@name}.sql"
        Sync (=> @adventure()), (err, result) =>
          @client.end()
          if err
            console.error "An error occurred!".red.bold
            console.error err.message.red.underline

  # Public: Run a function inside of a db transaction
  #
  # Does what it says on the tin. Just runs `BEGIN`, executes your code (which
  # presumably executes some sql and stuff), then runs `COMMIT` unless an
  # uncaught exception occurs.
  #
  # * `cb`: {Function} Function to execute.
  #
  # ## Examples
  #
  # ```coffee
  # @transaction =>
  #   @sql file: 'intransaction.sql'
  # ```
  #
  # Returns the result of calling `cb`.
  transaction: (cb) ->
    console.log "Beginning transaction".blue.underline
    @sql "BEGIN;"
    try
      cb()
    catch e
      console.error "An error occurred, rolling back".red.underline
      @sql "ROLLBACK;"
      throw e
    @sql """-- Ending transaction!
            COMMIT;"""

  # Public: Run a function in a retry loop.
  #
  # Run a function over and over again until it doesn't throw an error or run
  # out of allotted 'lives' (tries).
  #
  # * `opts`: Options {Object}.
  #   * `okErrors`: An {Array} of {RegExp}s to try to match against when an
  #      error occurs. If any of them matches, we retry.
  #   * `times`: {Number} of times we try before we give up. Default is 10.
  #   * `wait`: {Number} of milliseconds to wait before each retry. Default is
  #     5000
  #
  # ## Examples
  #
  # Retry up to 10 times with 5000 millisecond pauses.
  #
  # ```coffee
  # @retry =>
  #   @sql file: 'foo.sql'
  # ```
  #
  # Retry with your own rules
  #
  # ```coffee
  # @retry times: 5, wait: 10000, okErrors: [/concurrent transaction/] =>
  #   @sql file: 'intransaction.sql'
  # ```
  #
  # Returns the result of calling `cb`.
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
            Sync.sleep(wait)
            times -= 1
          else
            console.error "Out of lives... I give up.".red.underline
            throw e

  # Public: Run sql code in a string or file, fulfilling mustache templates.
  #
  # * `queries`: {String} with sql code or an {Object} with a `file` property.
  #   If a `file` is passed, look for it in the quest's `sql/` directory.
  # * `view`: (optional) {Object} to fill in a mustache template with.
  # * `cb`: Use a callback rather than be synchronous. NOT RECOMMENDED UNLESS
  #   YOU KNOW PRECISELY WHAT YOU'RE DOING.
  #
  # Returns an {Object} with the results of the last query in the block of sql
  # or file passed. This object will have a `rows` property.
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
