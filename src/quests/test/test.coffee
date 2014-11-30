Quest = require '../../quest'

module.exports =
class TestQuest extends Quest
  @adventure: ->
    console.log "I'm Adventuring!"
