require 'coffee-script/register'
path = require 'path'
fs = require 'fs'
colors = require 'colors'
read = require 'read'
nomnom = require 'nomnom'

splitAt = (target, items) ->
  index = items.indexOf target
  if index > -1
    beginning = items.slice(0, index)
    end = items.slice(index + 1)
    [beginning, end]
  else
    [items, []]

[args, questOpts] = splitAt '--', process.argv.slice(2)

opts = nomnom()
  .script 'sqlquest'
  .option 'user', abbr: 'u', required: true, help: 'Database username'
  .option 'pass', abbr: 'p', help: 'Database password'
  .option 'host', abbr: 'H', required: true, help: 'Database host'
  .option 'db',   abbr: 'd', required: true, help: 'Database name'
  .option 'quests', abbr: 'q', help: 'Where to find quests'
  .option('time', abbr: 't', flag: true, default: true,
          help: 'Print the runtime of each query')
  .option 'quest', position: 0, help: 'Which quest to embark on!'
  .option '', help: "Everything after this is passed to the quest."
  .parse(args)

questOpts = nomnom().parse(questOpts)

main = (opts, questOpts) ->
  printHeader = (text) ->
    console.log '########################################################'.gray
    console.log text.gray.bold
    console.log '########################################################'.gray

  if opts.quests
    quests = path.resolve(opts.quests)
  else
    quests = path.resolve('quests')
    if not fs.existsSync(quests)
      quests = "./quests"

  try
    questPath = "#{quests}/#{opts.quest}/#{opts.quest}"
    Quest = require questPath

    printHeader "Beginning the #{opts.quest} quest!"

    new Quest(opts.host, opts.db, opts.user,
              opts.pass, opts.time, opts.quest,
              questOpts)
  catch e
    if e.message == "Cannot find module '#{questPath}'"
      console.error "No such quest is available."
    else
      throw e

opts.pass ?= process.env.PGPASSWORD

if opts.pass?
  main opts, questOpts
else
  read prompt: 'Password:', silent: true, (err, pass) ->
    if pass
      opts.pass = pass
      main opts, questOpts
    else
      console.error "A password is necessary to venture forth.".red
