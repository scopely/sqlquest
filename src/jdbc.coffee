Q = require 'q'
co = require 'co'
fs = require 'fs'
ResultSet = require 'jdbc/lib/resultset'

class JDBCJVM
  constructor: (@config) ->
    jvm = require 'jdbc/lib/jinst'

    if not jvm.isJvmCreated()
      deps = fs.readdirSync('drivers/').map (dep) ->
        './drivers/' + dep
      jvm.setupClasspath deps

    JDBC = require 'jdbc'

    @config.minpoolsize ?= 1
    @config.maxpoolsize ?= 3

    @jdbc = new JDBC(@config)

  init: ->
    Q.ninvoke @jdbc, "initialize"

  getConnection: ->
    Q.ninvoke @jdbc, "reserve"

  releaseConnection: (conn) ->
    Q.ninvoke @jdbc, "release", conn

  createStatement: (conn) ->
    Q.ninvoke conn, "createStatement"

  logQueryLogs: (statement) ->
    statement = statement._s
    if statement.hasMoreLogsSync()
      logs = statement.getQueryLogSync()
      logLength = logs.sizeSync()
      if logLength == 1
        console.log logs.getSync(0)
      else if logLength > 1
        for i in [0..logLength-1]
          console.log logs.getSync(i)

  resultSetToObj: (resultset) ->
    Q.ninvoke resultset, "toObject"

  executeQuery: (statement, sql, logs) ->
    promise = Q.ninvoke(statement, "execute", sql)
    if logs
      interval = setInterval (=> @logQueryLogs(statement)), 1000
      promise.then (res) ->
        clearInterval interval
        res
    else
      promise

module.exports = JDBCJVM
