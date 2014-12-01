fs = require 'fs'
path = require 'path'
glob = require 'glob'
mkdirp = require 'mkdirp'

{print} = require 'sys'
{spawn} = require 'child_process'

run = (script, args, cb) ->
  args.split ' ' if typeof(args) == 'string'
  app = spawn script, args
  app.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  app.stdout.on 'data', (data) ->
    print data.toString()
  app.on 'exit', (code) ->
    cb?() if code is 0

copyFile = (inFile, outFile) ->
  mkdirp path.dirname(outFile), (err) ->
    return console.error(err) if err
    fs.writeFileSync outFile, fs.readFileSync(inFile)
    console.log "Copied #{inFile} to #{outFile}"

build = (watch) ->
  options = ['-c', '-o', 'lib', 'src']
  options.unshift('-w') if watch
  run 'coffee', options

task 'build:clean', 'rm build artifacts (lib/)', ->
  console.log 'Removing lib/'
  run 'rm', ['-r', 'lib/']

task 'build:copysql', 'Copy sql into lib', ->
  console.log 'Copying sql'
  glob 'src/**/*.sql', (err, files) ->
    for i, file of files
      outFile = path.join('lib', file.slice(4))
      copyFile(file, outFile)

option '-w', '--watch', 'Compile on save'
task 'build', 'Build lib/ from src/', (options) ->
  invoke 'build:clean'
  invoke 'build:copysql'
  console.log 'Compiling coffeescript'
  build(options.watch)
