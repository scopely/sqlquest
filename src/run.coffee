require 'coffee-script/register'
colors = require 'colors'
opts = require 'nomnom'
  .script 'sqlquest'
  .option 'user', abbr: 'u', required: true, help: 'Database username'
  .option 'pass', abbr: 'p', required: true, help: 'Database password'
  .option 'host', abbr: 'H', required: true, help: 'Database host'
  .option 'db',   abbr: 'd', required: true, help: 'Database name'
  .option 'quest', position: 0, help: 'Which quest to embark on!'
  .parse()

printHeader = (text) ->
  console.log '########################################################'.gray
  console.log text.gray.bold
  console.log '########################################################'.gray

printHeader "Beginning the #{opts.quest} quest!"

try
  if opts.quest
    Quest = require "./quests/#{opts.quest}/#{opts.quest}"
    new Quest(opts.host, opts.db, opts.user, opts.pass, opts._)
  else
    console.error "Need a quest to go on!"
catch e
  if e.message == "Cannot find module '#{opts.quest}'"
    console.log "No such quest is available."
  else
    throw e
