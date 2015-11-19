Quest = require '../../src/quest'

module.exports =
class HiveExampleQuest extends Quest
  adventure: ->
    result = yield @sql """CREATE TABLE IF NOT EXISTS sqlquesttest (x int);
             INSERT OVERWRITE TABLE sqlquesttest
               SELECT * FROM (
                 SELECT STACK(3, 1, 2, 3)
               ) s;
             SELECT * FROM sqlquesttest;"""
    console.log result

    result = yield @sql """DROP TABLE sqlquesttest"""
