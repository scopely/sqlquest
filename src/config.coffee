fs = require 'fs'
_ = require 'lodash'
toml = require 'toml'

module.exports =
  # Private: Read config from a toml file.
  #
  # * `tomlPath`: Path to the toml config file.
  #
  # Returns an {Object}.
  readConfig: (tomlPath) ->
    tomlPath ?= process.env.CONFIG_PATH or "config.toml"
    if fs.existsSync tomlPath
      toml.parse fs.readFileSync(tomlPath)
    else
      {}

  # Private: Using toml config, add affqis options to the command line parser
  #
  # For each realm configured in affqis config, add
  # <realm>_[host|port|user|db|pass] to our option parser. Additionally,
  # the password arg can be set via an environment variable.
  #
  # * `opts`: Default options to add to.
  # * `config`: Parsed TOML config.
  addAffqisOpts: (opts, config) ->
    affqisOpts = config.affqis
    if affqisOpts
      realms = _.omit affqisOpts, ["host", "port"]
      for realm, config of realms
        opts["#{realm}_user"] =
          help: "User for #{realm}"
        opts["#{realm}_pass"] =
          help: "Password for #{realm}"
          default: _.get process.env, "#{realm}_PASSWORD".toUpperCase()
        opts["#{realm}_host"] =
          help: "Host for #{realm}"
        opts["#{realm}_port"] =
          help: "Port for #{realm}"
        opts["#{realm}_db"] =
          help: "DB for #{realm}"
      opts
    else
      opts
