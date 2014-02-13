# Deal with repeated execution
fs     = require 'fs'
exec   = require('child_process').exec
path   = require 'path'
target = require './target'

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
  
triggerCommand = (cmd, cb, wait) ->
  exec "#{cmd}", (err, stdout, stderr) ->
    process.stdout.write stdout
    if stderr != ''
      process.stdout.write ' >> stderr below'
      process.stderr.write stderr
    setTimeout cb, wait

# Actually execute the command
execCommand = (target, e, cliInput) ->
  [cmd, wait, quiet] = [
    cliInput.cmd
    cliInput.options['--time']
    cliInput.options['--quiet']
  ]
  triggered[target.label] = triggered[target.label] || e
  if not running
    running = true; setTimeout (->
      printTriggered triggered, cliInput if not quiet
      triggered = {}
      triggerCommand cmd, (-> running = false), parseInt(wait, 10)), 100

# Watch a target, whether file or folder
watchTargetArg = (arg, cliInput) ->
  cb = ((t,e,fn) -> execCommand t, e, cliInput)
  target.create arg, arg, cliInput.options['--hidden'], cb

module.exports = {
  watchTargetArg: watchTargetArg
}
