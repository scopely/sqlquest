fs = require 'fs'
path = require 'path'

# Private: If a path contains a sql file, return it.
#
# * `path`: {String} path to a directory.
#
# Returns null or a {String} which is the path to the file that was found.
# Makes the path absolute.
findSql = (questPath) ->
  files = fs.readdirSync questPath
  for i, file of files
    if path.extname(file) == ".sql"
      return path.resolve(path.join(questPath, file))

# Private: Find a quest board somewhere on Pandora.
#
# Looks up a {Quest} in the `quests` directory. If no quest module is found then
# we just try to find a sql file to run with the default Quest implementation.
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
      if fs.existsSync findSql(path.dirname(questPath))
        [questPath, require './quest']
      else
        throw e
    else
      throw e

module.exports =
  findQuest: findQuest
  findSql: findSql
