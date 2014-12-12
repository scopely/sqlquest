Quest = require '../../src/quest'

module.exports =
class OptionQuest extends Quest
  options:
    name:
      abbr: 'n'
      help: "It's yer darn name!"

  adventure: ->
    @sql "SELECT '#{@opts.name}';"
