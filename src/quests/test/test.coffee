Quest = require '../../quest'

module.exports =
class TestQuest extends Quest
  adventure: ->
    try
      @sql 'SELECT 23D23+23D23;'
    catch e
      console.log e
    console.log(@sql('SELECT 2 + 2 as foo;').rows[0].foo)
    console.log(@sql file: 'test.sql')
