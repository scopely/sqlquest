fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

build = (callback) ->
  coffee = spawn 'coffee', ['-c', '-o', 'lib', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'build:clean', 'rm build artifacts (lib/)', ->
  console.log 'Removing lib/'
  fs.rmdir 'lib', ->

task 'build', 'Build lib/ from src/', ->
  invoke 'build:clean'
  console.log 'Compiling coffeescript'
  build()
