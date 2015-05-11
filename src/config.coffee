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

  # Private: Merge config and options, consolidating affqis command options.
  #
  # We can't just merge in [realm]_host and such with the config in toml files
  # without some logic to do so.
  #
  # Returns {Object} of merged configuration values.
  mergeConfig: (opts, config) ->
    affqisConfig = config.affqis ? {}
    config = _.merge opts, config

    addKeys = (realm, config) ->
      keys = ["#{realm}_user", "#{realm}_pass",
              "#{realm}_host", "#{realm}_port",
              "#{realm}_db"]

      for k in keys
        if value = config[k]
          configKey = k.split("_")[1]
          config.affqis[realm][configKey] = value
          delete config[k]
      config

    realms = Object.keys(_.omit(affqisConfig, ["host", "port"]))
    for realm in realms
      addKeys realm, config

    config
