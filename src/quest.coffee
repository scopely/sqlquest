# Questing library! Everything you need for your adventure. It isn't
# safe to go alone.
Sync = require 'sync'
fs = require 'fs'
path = require 'path'
pg = require('pg').native
colors = require 'colors'
Mustache = require 'mustache'
Table = require 'cli-table'
_ = require 'lodash'
EventEmitter = require('events').EventEmitter

{findSql} = require './hunter'
Splitter = require './split'
{time} = require './timing'

# Private: Render text with a view, or return text if view isn't a thing.
render = (text, view) ->
  if view
    Mustache.render text, view
  else
    text

module.exports =

# Public: Base quest class.
#
# {Quest} is the important part of the equation. Its methods make up the DSL
# that makes sqlquest special and powerful. Extend this class and implement the
# {Quest::adventure} method to create a quest. When a subclass of {Quest} is
# instantiated, it runs its {Quest::adventure} method inside of a fiber with
# [node-sync](https://github.com/ybogdanov/node-sync). The provided methods are
# synchronous by default, and this is a core part of what makes the {Quest} DSL
# powerful. {Quest::sql} can take a callback, but by default it executes
# queries synchronous so that you can author your SQL quests (jobs) in a clean,
# easy, readable way.
#
# If instantiated with no adventure method, defaults to just trying to run a sql
# script of the quest's name in the quest's sql directory, with options passed.
#
# ## Examples
#
# The simplest example is a completely blank implementation. Just don't have an
# implementation at all. No coffee! This will cause sqlquest to simply look for
# any given `.sql` file in the quest directory if and only if it is the only
# file in the directory. This covers the most trivial usecases. For more
# advanced usage where you want to embed sql, deal with results of queries, run
# multiple files, do retries, etc, you'll want to implement
# {Quest::adventure}.
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
class Quest extends EventEmitter

  # Private: Construct a quest instance.
  #
  # * `cliOption`: {Object} of command line options + config:
  #   * `host`: {String} Hostname of the database.
  #   * `db`: {String} Name of the database.
  #   * `user`: {String} Database user.
  #   * `pass`: {String} Database password.
  #   * `time`: {Boolean} Set to false to not print execution time of queries.
  #   * `splitter`: {String} URL to hit to split sql.
  # * `questPath`: {String} path to this quest.
  # * `questOpts`: {Object} Command line options for the quest.
  constructor: ({host, port, db, user, pass, url, time, splitter, output},
                @questPath, @opts) ->
    connString = url ? "postgres://#{user}:#{pass}@#{host}:#{port}/#{db}"
    @silentErrors = false
    @splitter = splitter
    @output = output
    @time = time
    @name = path.basename(@questPath)
    @sqlPath = path.join @questPath, 'sql'
    @client = new pg.Client(connString)
    @setAdventure()
    @options ?= {}
    @plugins ?= []

    @opts = require('nomnom')
      .options @options
      .usage "sqlquest #{@name} [OPTIONS]"
      .parse @opts

    @registerPlugins()

    @emit "connectStart", @client
    @client.connect (err) =>
      if err
        @emit 'connectionError', err
        console.error "Couldn't connect!".red.bold
        console.error err.message.red
      else
        @emit "adventureStart"
        Sync (=> @adventure()), (err, result) =>
          @client.end()
          @emit 'adventureFinish', result
          if err or @silentErrors
            @emit 'adventureError', err
            console.error "Errors occurred!".red.bold
            console.error err.message.red.underline if err
            console.error()
            process.exit 1

  # Private: Register plugins specified in @plugins.
  #
  # If the plugin path is absolute or isn't relative to `_dirname` then
  # just require it, otherwise make the path absolute by adding @questPath to
  # it.
  registerPlugins: ->
    for plugin in @plugins
      unless _.startsWith(plugin, '/') or not _.startsWith(plugin, '.')
        plugin = path.join(@questPath, plugin)
      require(plugin)(@)

  # Private: Setup the {Quest::adventure} function.
  #
  # Does nothing if {Quest::adventure} is implemented. Otherwise, sets
  # {Quest::adventure} to a stub function that just hunts down a sql file and
  # executes it if present, outputting any rows as a table. This covers most
  # use cases.
  setAdventure: ->
    @adventure ?= =>
      console.log "No quest module found. Just running SQL.".bold
      @table @sql(file: findSql(@questPath), @opts)

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

  # Public: Add a helper to the class prototype.
  #
  # * `name`: {String} name of the helper.
  # * `f`: {Function} function to associate the helper with.
  addHelper: (name, f) ->
    this.__proto__[name] = f

  # Public: Run a function in a retry loop.
  #
  # Run a function over and over again until it doesn't throw an error or runs
  # out of allotted 'lives' (tries).
  #
  # * `opts`: Options {Object}.
  #   * `okErrors`: An {Array} of {RegExp}s to try to match against when an
  #      error occurs. If any of them matches, we retry.
  #   * `times`: {Number} of times we try before we give up. Default is 10.
  #   * `wait`: {Number} of milliseconds to wait before each retry. Default is
  #     5000
  #   * `silent`: {Boolean} indicating whether or not we should throw an error
  #     if we run out of lives and fail. `false` by default, meaning an error
  #     will be thrown if we run out of tries. Set this to true to silently
  #     skip over the failure and simply track the error and report failure at
  #     the end of the job.
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

    # Arg shuffling
    if typeof(opts) == 'function'
      cb = opts
      opts = {}

    opts.wait ?= 5000
    opts.times ?= 10
    opts.silent ?= false
    error = null
    @emit 'retryLoopStart', opts
    while opts.times > 0
      @emit 'retry', opts
      try
        result = cb()
        @emit 'retryLoopFinish', opts, result
        result
      catch e
        error = e
        console.trace e
        match = (regex) -> e.message.match regex
        if not opts.okErrors or opts.okErrors.some(match)
          console.error "Error occurred: #{e.message}".red.underline
          console.log "Retrying in #{opts.wait}ms.".red.bold
          console.log "Retries remaining: #{opts.times}".red.bold
          Sync.sleep(opts.wait)
          opts.times -= 1
        else
          throw e

    # Out of lives, time to give up...
    console.error "Out of lives... I give up.".red.underline
    @emit 'retryLoopFail', opts, error
    if opts.silent
      @silentErrors = true
      console.error e.message.red.underline
      return
    else
      throw error

  # Public: Print out rows as a table.
  #
  # Header, row, row, row your boat gently down the stream, merily, merily,
  # merily tables are such a dream.
  #
  # * `sqlResult`: Result {Object} from a call to {Quest::sql}.
  # * `opts`: (optional) An {Object} of options.
  #   * `trimWhitespace`: {Boolean} indicating if we should trim excess
  #     whitespace from rows. Defaults to true. Unbearable otherwise.
  #
  # ## Examples
  #
  # ```coffee
  # @table @sql(file: 'foo.sql')
  # ```
  table: (sqlResult, {trimWhitespace, print}={}) ->
    print ?= true
    trimWhitespace ?= true
    if sqlResult.rows.length > 0
      columns = (field.name for field in sqlResult.fields)
      opts = head: columns
      table = new Table(opts)

      # Get values, ensuring ordering is the same as our columns.
      values = sqlResult.rows.map (val) ->
        columns.map (column) ->
          value = val[column]
          if trimWhitespace and typeof(value) == 'string'
            value.trim()
          else
            if value instanceof Date
              value = value.toString()
              match = value.match /(.*)\w{3}-\d{4} \(\w+\)$/
              match[1] or value
            else
              value ? ''

      table.push.apply table, values
      if print
        console.log table.toString()
      else
        table
    else
      console.log "Nothing to output.".gray

  jsonify: (sqlResult) ->
    console.log JSON.stringify(sqlResult.rows, undefined, 2)

  outputRows: (sqlResult) ->
    switch @output
      when 'table' then @table sqlResult
      when 'json' then @jsonify sqlResult
      else console.log "output of file type #{@output} not supported"

  # Public: Run sql code in a string or file, fulfilling mustache templates.
  #
  # * `queries`: {String} with sql code or an {Object}. If it is an object, it
  #   can have the following properties:
  #     * `text`: {String} of sql to execute.
  #     * `file`: {String} filename of a file in the quest's `sql` directory.
  #               If the path is absolute, will just execute it wherever it is.
  #     * `split`: {Boolean} split the sql queries into chunks using an API.
  #       This allows timing of individual queries, as well as more granular
  #       error handling. `true` by default.
  #     * `params`: {Array} of parameters to fill in node-postgres query params.
  # * `view`: (optional) {Object} to fill in a mustache template with.
  # * `cb`: (optional) Use a callback rather than be synchronous. NOT
  #   RECOMMENDED UNLESS YOU KNOW PRECISELY WHAT YOU'RE DOING.
  #
  # Returns an {Object} with the results of the last query in the block of sql
  # or file passed. This object will have a `rows` property.
  sql: (queries, view, cb) ->
    split = true
    if view instanceof Function
      cb = view
      view = null
    if typeof(queries) != 'string'
      split = queries.split if queries.split?
      params = queries.params
      if queries.file
        if queries.file == path.resolve(queries.file)
          sqlPath = queries.file
        else
          sqlPath = path.join @sqlPath, queries.file
        console.log ">>".blue.bold, "#{sqlPath}".blue.bold if queries.file
      rawQueries = queries.text or fs.readFileSync(sqlPath, encoding: 'utf-8')
    params ?= []
    queries = render rawQueries ? queries, view
    if split
      @emit 'splitStart', queries, view
      queries = new Splitter(@splitter).split queries
      @emit 'splitFinish', queries, view
    result = null
    count = queries.length
    time 'Total Execution Time', =>
      @emit 'stepStart', queries, view
      for i, query of queries
        i = parseInt(i)
        counter = i
        console.log "\nNow executing #{counter+1} of #{count}"
        console.log "\n#{query}\n".green
        @emit 'queryStart', i, query
        if cb?
          @client.query(query, params, cb)
        else
          if @time
            result = time 'Execution Time', =>
              @client.query.sync(@client, query, params)
        @emit 'queryFinish', i, query
        console.log()
      @emit 'stepFinish', queries, view
      console.log()
    result
