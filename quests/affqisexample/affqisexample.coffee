Quest = require '../../src/quest'

module.exports =
class AffqisExampleQuest extends Quest
  databases: ["pg", "hive"]
  adventure: ->
    @sql "select 1"
