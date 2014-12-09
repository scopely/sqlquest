Quest = require '../../src/quest'

module.exports =
class ParamExampleQuest extends Quest
  adventure: ->
    @sql "CREATE TEMP TABLE foo (n integer);"
    @sql text: "INSERT INTO foo VALUES ($1), ($2), ($3);", params: [1, 2, 3]
    @table @sql("SELECT * FROM foo;")
