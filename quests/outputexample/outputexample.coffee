Quest = require '../../src/quest'

module.exports =
class OutputExampleQuest extends Quest
  adventure: ->

    console.log "So, what's a person like?".bold

    @sql """
         CREATE TEMP TABLE people (
           name varchar(256),
           birthdate date,
           title varchar(256)
         );
         """

    console.log "It's like that.".italic.gray

    console.log "What are these creatures?".bold

    res = @sql """INSERT INTO people
                    VALUES
                      ('Anthony', '02-02-1994', 'Brother of Matthew'),
                      ('Daniel', '07-08-1993', 'Son of Doug'),
                      ('Scott', '11-19-1992', 'Son of Kim');"""

    console.log "They're us. They're all of us.".italic.gray

    @outputRows @sql "SELECT * from people;"
