Quest = require '../../src/quest'

module.exports =
class AffqisExampleQuest extends Quest
  databases: ["hive", "pg"]
  adventure: ->
    x = @sql """CREATE TABLE sqltest (x int);
                INSERT OVERWRITE TABLE sqltest
                  SELECT * FROM (
                    SELECT STACK(3, 1, 2, 3)
                  ) s;
                SELECT * FROM sqltest;"""
    console.log x

    y = @sql """DROP TABLE sqltest;"""
    console.log y

    z = @sql text: """SELECT 1, 2, 3""", db: "pg"
    console.log z
