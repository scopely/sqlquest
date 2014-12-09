fs = require 'fs'
_ = require 'underscore'
toml = require 'toml'

module.exports =

  # Private: Merge toml config at a path with some opts.
  #
  # If `tomlPath` exists, read it and merge the resulting object with opts.
  #
  # * `tomlPath`: {String} to a possible toml config file.
  # * `opts`: {Object} of parsed command line options.
  #
  # Returns an {Object} of the merged config.
  mergeConfig: (tomlPath, opts) ->
    if tomlPath and fs.existsSync tomlPath
      _.extend toml.parse(fs.readFileSync(tomlPath)), opts
    else
      opts
