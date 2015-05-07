Sync = require 'sync'
autobahn = require 'autobahn'
_ = require 'lodash'
moment = require 'moment'

# Private: Establish a connection to an affqis wamp server.
#
# * `realm`: {String} Realm (database) to connect to.
# * `host`: {String} hostname of affqis server.
# * `port`: {Number} port number of affqis server.
# * `cb`: {Function} callback to get called with an error if we
#         fail to establish a connection, or a session if we succeed.
connect = (realm, host, port, cb) ->
  affqisUrl = "ws://#{host}:#{port}/affqis"
  @connection = new autobahn.Connection
    url: affqisUrl
    realm: realm
    max_retries: 0

  @connection.onopen = (session) ->
    cb(null, session)

  @connection.onclose = (reason) =>
    switch reason
      when "unreachable"
        console.error "Cannot establish connection to #{affqisUrl}"
        cb(new Error(reason))
      when "lost"
        console.error "Connection to #{affqisUrl} lost"
      when "closed"
        console.log "Connection to #{affqisUrl} closed"

  connection.open()

# Private: Establish and store a JDBC connection.
#
# Eventually this will take a password as well, but for the moment we're
# using affqis solely for hive support where they're unnecessary.
#
# * `session`: {autobahn.Session} Affqis session.
# * `config`: {Object} with host, port, user, and optionally db keys.
# * `cb`: {Function} Callback to be called with an error if we get a wamp
#         failure, or if successful the connection id.
connectJdbc = (session, {host, port, db, user}, cb) ->
  if db?
    connectArgs = [user, host, port, db]
  else
    connectArgs = [user, host, port]
  session.call('connect', connectArgs)
    .then((result) -> cb null, result)
    .catch(cb)

# Private: Normalize a row to as close to node-postgres format as reasonable.
#
# Until we entirely move to affqis, we should match the row format
# returned by node-postgres. Eventually we'll probably want to get
# affqis output right and tweak sqlquest to just use that.
#
# * `row`: {Array} of {Object} with name, type, and value keys representing
#          columns
#
# Returns {Object} of column names to values.
normalizeRow = (row) ->
  addColumn = (acc, {name, type, value}) ->
    if type == "date" or type == "timestamp"
      value = moment(value)
    acc[name.split('.')[1]] = value
    acc
  row.reduce(addColumn, {})

# Private: Execute a query via affqis.
#
# * `session`: Autobahn affqis session.
# * `id`: {String} jdbc connection id returned from affqis.
# * `hql`: {String} sql statement to execute (exactly one statement).
# * `cb`: {Function} callback that'll get called with errors or our results.
executeQuery = (session, id, hql, cb) ->
  rows = []
  session.call('execute', [id, hql])
   .then((topic) ->
     session.subscribe(topic, ([event, row]) ->
       if event == "row"
         rows.push JSON.parse(row)
       else
         cb null,
          rows: rows.map(normalizeRow)
          rowCount: rows.map.length
          fields: rows[0].map((data) -> _.pick data, ['name', 'type'])
     ).catch(cb))
   .catch(cb)

# Public: Connect to affqis and establish a JDBC connection.
#
# * `realm`: {String} Realm (database) name.
# * `config`: {Object} Affqis config. Should have host, port, and realm configs,
#             each with host, port, user, and optionally pass and db.
#
# Returns an {Object} with session and id properties, suitable for passing to
# the also-exported `aql` function.
affqisConnect = (realm, config) ->
  realmConfig = config[realm]
  session = connect.sync null, realm, config.host, config.port
  jdbcId = connectJdbc.sync null, session,
    host: realmConfig.host
    port: realmConfig.port
    user: realmConfig.user

  {session: session, id: jdbcId}

# Public: Given a session, from `affqisConnect`, run a query and return results.
# * `session`: {Object} returned from `affqisConnect`
# * `sql`: {String} SQL statement (one single statement) to execute.
#
# Returns an {Array} of {Object}s representing rows.
aql = ({session, id}, sql) ->
  executeQuery.sync null, session, id, sql

module.exports =
  affqisConnect: affqisConnect
  aql: aql
