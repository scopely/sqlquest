require 'coffee-script/register'
path = require 'path'
fs = require 'fs'
colors = require 'colors'
read = require 'read'
nomnom = require 'nomnom'
toml = require 'toml'
_ = require 'underscore'

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

# Private: Merge toml config at a path with some opts.
#
# If `tomlPath` exists, read it and merge the resulting object with opts.
#
# * `tomlPath`: {String} to a possible toml config file.
# * `opts`: {Object} of parsed command line options.
#
# Returns an {Object} of the merged config.
mergeConfig = (tomlPath, opts) ->
  if tomlPath and fs.existsSync tomlPath
    _.extend toml.parse(fs.readFileSync(tomlPath)), opts
  else
    opts

# Separate all args after `--` so we can pass those on to the quest.
[args, questOpts] = splitAt '--', process.argv.slice(2)

opts = nomnom()
  .script 'sqlquest'
  .option 'user', abbr: 'u', help: 'Database username'
  .option 'pass', abbr: 'P', help: 'Database password'
  .option 'host', abbr: 'H', help: 'Database host'
  .option 'port', abbr: 'p', help: 'Database port', default: 5432
  .option 'url', abbr: 'U', help: """Connection URL:
                                     (postgres://user:pass@host:port/db)"""
  .option 'db', abbr: 'd', help: 'Database name'
  .option 'quests', abbr: 'q', help: 'Where to find quests'
  .option('config',
    abbr: 'c',
    default: 'config.toml',
    help: 'Read config from this file'
  )
  .option('time',
    abbr: 't',
    flag: true,
    default: true
    help: 'Print the runtime of each query'
  )
  .option 'quest', position: 0, help: 'Which quest to embark on!'
  .option '', help: "Everything after this is passed to the quest."
  .parse(args)

opts = mergeConfig(opts.config, opts)

# Just throw it at the wall. Should probably let quests override how they handle
# their command line args.
questOpts = nomnom().parse(questOpts)

# Private: Find a quest board somewhere on Pandora.
#
# Looks up a {Quest} in the `quests` directory. If it isn't found, but the
# directory exists with a `sql/` subfolder containing a sql file of the same
# name, instantiate the default Quest class.
#
# * `quests`: {String} path to the directory containing quests. If `null`,
#             makes a relatively reasonable guess that it is 'quests'
# * `quest`: {String} quest to look for.
#
# Returns a {Quest} or throws an {Error}.
findQuest = (quests, quest) ->
  quests = path.resolve (quests or 'quests')
  questPath = "#{quests}/#{quest}/#{quest}"
  try
    [questPath, require questPath]
  catch e
    if e.message.indexOf("Cannot find module") > -1
      sqlPath = path.join path.dirname(questPath), 'sql', "#{quest}.sql"
      if fs.existsSync(sqlPath)
        [questPath, require './quest']
      else
        throw e
    else
      throw e

# Private: Entry point function.
#
# Tries to find and run the specified quest. Handle errors if
# they boil up.
#
# * `opts`: The {Object} output of parsing args with nomnom.
# * `questOpts` The {Object} output of parsing quest args with nomnom.
main = (opts, questOpts) ->
  printHeader = (text) ->
    console.log '########################################################'.gray
    console.log text.gray.bold
    console.log '########################################################'.gray

  if opts.quests
    # Path to quests was passed in
    quests = path.resolve(opts.quests)
  else
    # Path to quests wasn't passed in, assume it's in the current directory.
    quests = path.resolve('quests')

  [questPath, Quest] = findQuest(quests, opts.quest)

  printHeader "Beginning the #{opts.quest} quest!"

  # Instantiate quest, which runs `adventure`.
  quest = new Quest(opts, path.dirname(questPath), questOpts)

# If opts wasn't passed on the command line, set it to the PGPASSWORD
# environment variable.
opts.pass ?= process.env.PGPASSWORD

if opts.pass ? opts.url?
  main opts, questOpts
else
  # No password was passed and no environment variable exists. Prompt
  # the user for input.
  read prompt: 'Password:', silent: true, (err, pass) ->
    if pass
      opts.pass = pass
      main opts, questOpts
    else
      console.error "A password is necessary to venture forth.".red
