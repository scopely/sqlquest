fs = require 'fs'
_ = require 'lodash'
toml = require 'toml'

module.exports =
  # Private: Read config from a toml file.
  #
  # Returns an {Object}.
  (databases) ->
    tomlPath = process.env.CONFIG_PATH or "config.toml"
    conf = if fs.existsSync tomlPath
      toml.parse fs.readFileSync(tomlPath)
    else
      {}
    if databases?.length
      dbs = {}
      configuredDbs = conf['databases']
      for database in databases
        dbs[database] = configuredDbs[database]
      conf['databases'] = dbs
      conf
    else
      conf
