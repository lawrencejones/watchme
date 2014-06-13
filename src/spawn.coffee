# Deal with repeated execution
fs     = require 'fs'
spawn  = require('child_process').spawn
path   = require 'path'
target = require './target'
parser = require './cmd_parser'
$q     = require 'q'

# Keep track of running and cache for changed
running = false
triggered = {}
options = null

formatLog = (event, label) ->
  "#{event}  #{label}"

printTriggered = (triggered, cliInput) ->
  console.log 'Triggered by: ['
  mssg = ("    #{formatLog(e, lbl)}" for own lbl,e of triggered).join ',\n'
  console.log "#{mssg}\n]"

# Runs the command built from cmdStr.
# Throws syntax errors.
triggerCommand = (cmdStr, cb, wait) ->
  cmd = parser.parse cmdStr
  done = cmd.init()
  cmd.pipe sout: process.stdout, serr: process.stderr
  done.then (code) ->
    console.log "Exited with code [#{code}]"
  done.catch (code) ->
    console.log "Failed with code [#{code}]"
  done.finally ->
    $q.delay(wait).then -> cb()
  done.complete()

# Actually execute the command
execCommand = (target, e, cliInput) ->
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
watchTargetArg = (arg, cliInput) ->
  cb = ((t,e,fn) -> execCommand t, e, cliInput)
  target.create arg, arg, cliInput.options['--hidden'], cb

module.exports = {
  watchTargetArg: watchTargetArg
}
