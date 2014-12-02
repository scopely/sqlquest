require 'coffee-script/register'
path = require 'path'
fs = require 'fs'
colors = require 'colors'
opts = require 'nomnom'
  .script 'sqlquest'
  .option 'user', abbr: 'u', required: true, help: 'Database username'
  .option 'pass', abbr: 'p', required: true, help: 'Database password'
  .option 'host', abbr: 'H', required: true, help: 'Database host'
  .option 'db',   abbr: 'd', required: true, help: 'Database name'
  .option 'quests', abbr: 'q', help: 'Where to find quests'
  .option 'quest', position: 0, help: 'Which quest to embark on!'
  .parse()

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

  new Quest(opts.host, opts.db, opts.user, opts.pass, opts._)
catch e
  if e.message == "Cannot find module '#{questPath}'"
    console.error "No such quest is available."
  else
    throw e
