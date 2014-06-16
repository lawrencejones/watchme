# Deal with repeated execution
fs      = require 'fs'
spawn   = require('child_process').spawn
path    = require 'path'
Targets = require './targets'
parser  = require './cmd_parser'
$q      = require 'q'

# Keep track of running and cache for changed
running = false
triggered = {}
options = null

formatLog = (event, label) ->
  "#{event}  #{label}"

# Throws error if str is unparsable
validateCmd = (cmdStr) ->
  cmd = parser.parse cmdStr

# Prints a triggered message.
printTriggered = (triggered, cliInput) ->
  console.log """
  Triggered by: [
  #{("    #{formatLog(e, lbl)}" for own lbl,e of triggered).join ',\n'}
  \n]"""

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

# Actually execute the command
triggerExec = () ->
  [cmd, wait, quiet] = [
    cliInput.cmd
    cliInput.options['--time']
    cliInput.options['--quiet']
  ]
  triggered[target.label] = triggered[target.label] || e
  if not running
    running = true; $q.delay(parseInt wait/4, 10).then ->
      printTriggered triggered, cliInput if not quiet
      triggered = {}
      triggerCommand cmd, (-> running = false), parseInt(wait, 10)

# Watch a target, whether file or folder
watchTarget = (arg, cmd, options) ->
  target.create arg, arg, cliInput.options['--hidden'], cb

module.exports = {
  watch: watchTarget
  validate: validateCmd
}
