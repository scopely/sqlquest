fs = require 'fs'
path = require 'path'
glob = require 'glob'
mkdirp = require 'mkdirp'

{print} = require 'sys'
{spawn} = require 'child_process'

build = (watch, callback) ->
  options = ['-c', '-o', 'lib', 'src']
  options.unshift('-w') if watch
  coffee = spawn 'coffee', options
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'build:clean', 'rm build artifacts (lib/)', ->
  console.log 'Removing lib/'
  fs.rmdir 'lib', ->

task 'build:copysql', 'Copy sql into lib', ->
  console.log 'Copying sql'
  glob 'src/**/*.sql', (err, files) ->
    for i, file of files
      outFile = path.join('lib', file.slice(4))
      outDir = path.dirname(outFile)
      console.log "Creating #{outFile}"
      mkdirp outDir
      fs.writeFileSync outFile, fs.readFileSync(file)

option '-w', '--watch', 'Compile on save'
task 'build', 'Build lib/ from src/', (options) ->
  invoke 'build:clean'
  invoke 'build:copysql'
  console.log 'Compiling coffeescript'
  build(options.watch)
