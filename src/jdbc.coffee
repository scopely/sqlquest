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
    @jdbc.initialize((err) -> console.error(err) if err)

jvm = new JDBCJVM
  url: process.argv[2]
  drivername: 'org.apache.hive.jdbc.HiveDriver'

conn = jvm.jdbc.reserve (err, {conn: conn}) ->
  conn.createStatement (err, statement) ->
    console.error err if err
    statement.executeQuery process.argv[3], (err, res) ->
      console.error err if err
      res.toObject (err, obj) ->
        console.error err if err
        console.log obj
  jvm.jdbc.release conn, (err) ->
    console.error err if err
