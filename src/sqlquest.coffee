require 'coffee-script/register'
path = require 'path'
fs = require 'fs'
colors = require 'colors'
read = require 'read'
nomnom = require 'nomnom'
_ = require 'lodash'
Sync = require 'sync'

{findSql, findQuest} = require './hunter'
{readConfig, addAffqisOpts} = require './config'

# Private: Split a list the first instance of an element
#
# * `target` Element of the list you want to split at.
# * `items` {Array} to split.
#
# Returns the original {Array} otherwise returns an {Array} of two {Array}s
# where the first contains everything prior to the `target` element and the
# second contains everything after. The `target` element isn't includes
splitAt = (target, items) ->
  index = items.indexOf target
  if index > -1
    beginning = items.slice(0, index)
    end = items.slice(index + 1)
    [beginning, end]
  else
    [items, []]

# Separate all args after `--` so we can pass those on to the quest.
[args, questOpts] = splitAt '--', process.argv.slice(2)

options =
  user:
    abbr: 'u'
    help: "PG/Redshift username"
  pass:
    abbr: 'P'
    help: "PG/Redshift password"
    default: process.env.PGPASSWORD
  host:
    abbr: 'H'
    help: 'PG/Redshift host'
  port:
    abbr: 'p'
    help: "PG/Redshift port"
    default: 5432
  url:
    abbr: 'U'
    help: "PG/Redshift URL (postgres://user:pass@host:port/db)"
  db:
    abbr: 'd'
    help: "PG/Redshift DB"
  quests:
    abbr: 'q'
    default: 'quests'
    help: "Where to find quests"
  splitter:
    abbr: 's'
    help: "Splitter API URL to use [http://sqlformat.org/api/v1/split]"
  time:
    abbr: 't'
    flag: true
    default: true
    help: "Print the runtime of each query."
  quest:
    position: 0
    help: "Which quest to embark on!"
  output:
    abbr: 'o'
    help: "Options are: table or json"
    default: "table"
  '':
    help: "Everything after this is passed to the quest."

config = readConfig()
console.log config
options = addAffqisOpts(options, config)
opts = nomnom()
  .script 'sqlquest'
  .options options
  .parse(args)
config = _.merge opts, config

# Private: Entry point function.
#
# Tries to find and run the specified quest. Handle errors if
# they boil up.
#
# * `opts`: Merged toml config and command line options.
# * `questOpts` The {Object} output of parsing quest args with nomnom.
main = (opts, questOpts) ->
  printHeader = (text) ->
    console.log '########################################################'.gray
    console.log text.gray.bold
    console.log '########################################################'.gray

  quests = path.resolve(opts.quests)

  [questPath, Quest] = findQuest(quests, opts.quest)

  printHeader "Beginning the #{opts.quest} quest!"

  # Instantiate quest, which runs `adventure`.
  quest = new Quest(opts, path.dirname(questPath), questOpts)

main config, questOpts
