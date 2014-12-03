# sqlquest

Ever wanted to go on an adventure but ended up taking an arrow to the knee?
No worries, sqlquest has your back!

## Purpose

sqlquest is meant to be a brutally simple SQL job DSL/runner. It's written in
coffeescript and is designed to be easy enough to use that non-programmers
can make use of it with little training, and engineers can use it for complex
tasks. You can have your coffee and drink it too.

## Usage

sqlquest is meant to be used from an install in another project. The idea is
that you'll create your own 'myawesomequests' package. Example:

```
$ mkdir myawesomequests
$ cd myawesomequests
$ npm init
... follow instructions
$ npm install --save sqlquest
$ ln -s node_modules/.bin/sqlquest sqlquest
```

With this symlink, you can run sqlquest from the top level of your project.

Create a directory called `quests/`. This is where you'll put all your quests.
Each quest is a directory (the name of the quest) with at a minimum a `.coffee`
file of the same name as the quest and, if your quest involves separate sql
files, `sql/` directory.

You can run quests like so:

```
$ ./sqlquest awesomequest
```

This will run the quest in `quests/awesomequest/`.

## Quests

So how do you go on these damned quests? Well, we have a DSL for that!

Create a file, `quests/awesomequest/sql/awesome.sql`:

```sql
CREATE TABLE numbers (
  n integer
);

INSERT INTO TABLE numbers VALUES
  (1),
  (2),
  (3),
  (4);

SELECT * FROM numbers
WHERE a_number > {{min}};
```

Now create a file called `quests/awesomequest/awesome.coffee`

```coffee
Quest = require 'sqlquest'

module.exports =
class AwesomeQuest extends Quest
  adventure: ->
    @sql file: 'awesome.sql', {min: @opts.min}
```

Now you can run your **awesome** quest like so:

```
$ ./sqlquest awesomequest -u myuser -H my.db.com -d mydb -- --min 2
```

You should now see sqlquest running each block of sql in your `awesome.sql` file
one by one, outputting the queries and their execution times. Since we passed an
object as the second arg to `@sql` the sql is assumed to contain mustache
syntax like `{{variable}}` which will be filled in with the object's data.

If ya really really wanted, you could just embed the sql in the file itself:

```coffee
Quest = require 'sqlquest'

module.exports =
  class AwesomeQuest extends Quest
    adventure: ->
      @sql """CREATE TABLE numbers (
                n integer
              );

              INSERT INTO TABLE numbers VALUES
                (1),
                (2),
                (3),
                (4);

              SELECT * FROM numbers
              WHERE a_number > {{min}};""",
        min: @opts.min
```

Pretty dope, right?

There are other helpers to make your adventure easier.

## Inventory

sqlquest has a number baked in potions to keep you healthy. Take a gander.

### transactions

You can do transactions the normal way, just by shoving `BEGIN` and such in
place, but there's also a helper for that:

```coffee
Quest = require 'sqlquest'

module.exports =
  class AwesomeQuest extends Quest
    adventure: ->
      @transaction =>
        @sql file: 'foo.sql'
        @sql file: 'bar.sql'
```

This simply takes the function passed to it and executes it after running
`BEGIN;`. If an uncaught error occurs, it will catch and run `ROLLBACK;` before
throwing the error back up. So, that's a little cooler than doing it yourself,
right?

### retries

Transactions are neat, but what if you want to perhaps retry in the event of an
error? Well, we've got a spell for that as well:

```coffee
Quest = require 'sqlquest'

module.exports =
  class AwesomeQuest extends Quest
    adventure: ->
      @retry =>
        @sql file: 'foo.sql'
        @sql file: 'bar.sql'
```

Does what it says on the tin. When just passed a function, it defaults the
number of retries allowed to 10 and the wait between retries to 5000
milliseconds. You can change that.

```coffee
@retry times: 5, wait: 2000 =>
  ...
```

Oh, and you can give it an array of regular expressions to only retry on
certain matching error messages.


```coffee
@retry times: 5, wait: 2000, okErrors: [/omg error/], =>
  ...
```

### little bobby tables

You probably want to see the results of queries sometimes. It's not trivial to
output them in a readable way.





Nah, I'm just kidding, we got something for that too:

```coffee
@table @sql(file: 'foo.sql')
```

That'll output the results as a table. Just like dat.

### All together now!

```coffee
Quest = require 'sqlquest'

module.exports =
  class AwesomeQuest extends Quest
    adventure: ->
      @retry times: 5, wait: 2000, okErrors: [/my silly error/], =>
        @transaction =>
          @sql file: 'foo.sql', {foo: 1, bar: 2}
          @table @sql(file: 'bar.sql')
```
