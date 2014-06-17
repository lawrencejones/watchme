# Deal with repeated execution
fs         = require 'fs'
spawn      = require('child_process').spawn
path       = require 'path'
Targets    = require './targets'
CmdParser  = require './cmd_parser'
$q         = require 'q'

# Given a command string, parses the command and then runs
# using stdout and stderr as default streams.
# Can throw syntax error.
runCommand = (cmdStr, cb) ->
  done = (cmd = parser.parse cmdStr).init()
  cmd.pipe sout: process.stdout, serr: process.stderr
  done.then (code) ->
    console.log "Exited with code [#{code}]"
  done.catch (code) ->
    console.log "Failed with code [#{code}]"
  done.finally -> cb()
  done.complete()

module.exports = class Spawn

  constructor: (cmdStr) ->
    @cmd = CmdParser.parse cmdStr

  # Runs the parsed command
  run: (stdout = process.stdout, stderr = process.stderr) ->

  

