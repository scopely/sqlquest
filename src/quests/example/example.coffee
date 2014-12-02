Quest = require '../../quest'

module.exports =
class ExampleQuest extends Quest
  makePeople: (peoples) ->
    peoples = peoples
      .map ({name, age}) -> "('#{name}', #{age})"
      .join ',\n'
    @sql file: 'people.sql', {people: peoples}

  getPeopleOlderThan: (minAge) ->
    try
      result = @sql """SELECT * FROM people
                       WHERE age > {{age}}""",
                    age: minAge

    catch e
      console.error "Failed to get people older than #{minAge}!"
      console.error e.message
      return []
    result.rows.map ({name}) -> name

  adventure: ->
    @makePeople [{name: 'Anthony', age: 20},
                 {name: 'Daniel', age: 21},
                 {name: 'Avram', age: 29}]

    console.log "People older than 20:".underline
    for i, person of @getPeopleOlderThan 20
      console.log "* #{person}".underline
    @transaction =>
      @sql "create temp table foo (x int);"
      @sql "insert into table foo VALUES ('on no');"

      # this will never happen
      @sql "create temp table bar as (select * from foo)"
