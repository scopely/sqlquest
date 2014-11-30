Quest = require '../../quest'

module.exports =
class TestQuest extends Quest
  adventure: ->
    console.log(@sql('SELECT 2 + 2 as foo;').rows[0].foo)
    console.log(@sql file: 'test.sql')
