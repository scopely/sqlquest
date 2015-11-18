Q = require 'q'
co = require 'co'
fs = require 'fs'

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

  executeQuery: (statement, sql) ->
    deferred = Q.defer()
    statement.executeQuery sql, (err, res) ->
      if err
        deferred.reject err
      else
        res.toObject (err, obj) ->
          if err
            deferred.reject err
          else
            deferred.resolve obj
    deferred.promise

co(->
  jvm = new JDBCJVM
    url: process.argv[2]
    drivername: 'org.apache.hive.jdbc.HiveDriver'
  yield jvm.init()
  connection = yield jvm.getConnection()
  connection = connection.conn
  statement = yield jvm.createStatement(connection)
  results = yield jvm.executeQuery(statement, process.argv[3])
  yield jvm.releaseConnection(connection)
  results
).then(console.log).catch(console.error)
