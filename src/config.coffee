fs = require 'fs'
_ = require 'lodash'
toml = require 'toml'

module.exports =
  # Private: Read config from a toml file.
  #
  # * `tomlPath`: Path to the toml config file.
  #
  # Returns an {Object}.
  (tomlPath) ->
    tomlPath ?= process.env.CONFIG_PATH or "config.toml"
    if fs.existsSync tomlPath
      toml.parse fs.readFileSync(tomlPath)
    else
      {}
