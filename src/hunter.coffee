fs = require 'fs'
path = require 'path'

# Private: If a path contains just a sql file, return it.
#
# * `path`: {String} path to a directory.
#
# Returns null or a {String} which is the path to the file that was found.
# Makes the path absolute.
findSql = (questPath) ->
  files = fs.readdirSync questPath
  if files.length == 1 and path.extname(files[0]) == ".sql"
    path.resolve path.join(questPath, files[0])

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
      if fs.existsSync findSql(path.dirname(questPath))
        [questPath, require './quest']
      else
        throw e
    else
      throw e

module.exports =
  findQuest: findQuest
  findSql: findSql
