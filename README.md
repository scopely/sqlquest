# sqlquest

Ever wanted to go on an adventure but ended up taking an arrow to the knee?
No worries, sqlquest has your back!

## Purpose

sqlquest is meant to be a brutally simple SQL job DSL/runner. It's written in
coffeescript and is designed to be easy enough to use that non-programmers
can make use of it with little training.

## Usage

The idea behind sqlquest is that you'll fork the repository and start adding
your own quests. Upgrading just requires merging back upstream. Just make
sure that you don't make changes to sqlquest core downstream that you don't
intend to contribute back to upstream – you may end up with nasty merge
conflicts in the future.

First thing you'll want to do is build the project. You should make sure you
build every time you change/add quests.

```
$ cake build
```

This will build the project for ya.

Quests (jobs) are just directories in `src/quests/` that contains coffeescript
files and possibly `sql/` directory. Take a look at `src/quests/example` for a
heavier example/demo.

Each quest should at a minimum have a file called `<questname>.coffee`. This
module should export one class that extends `Quest` from `../quest`. Quests
need to implement one method: `adventure`

You can run quests via the `sqltest` command line tool.

```
$ bin/sqltest aquest -u dbuser -p dbpassword -H your.db.net -d dbname
```

Here is a very basic quest:

```coffeescript
Quest = require '../quest'

module.exports =
class AwesomeQuest extends Quest
  adventure: ->
    @sql 'CREATE TABLE myawesometable AS (SELECT * FROM somelessertable);'
    result = @sql 'SELECT count(*) from myawesometable;'
    console.log result.rows[0].count
```

You can also put sql in files. Let's assume you put the create table into a
sql file called `foo.sql` at `src/quests/awesome/sql`:

```coffeescript
Quest = require '../quest'

module.exports =
  class AwesomeQuest extends Quest
    adventure: ->
      @sql file: 'foo.sql'
      result = @sql 'SELECT count(*) from myawesometable;'
      console.log result.rows[0].count
```

Easy enough, right? Note that the result of each `sql` call is the result
of the last query in the sql.

You can even put mustache templates in your sql files! Just pass an object to
fulfill the template as the second argument to `@sql`!

```coffeescript
@sql "SELECT * from {{{table}}};", table: 'schema.table'
```

For a heavier example, look at `src/quests/example`.
