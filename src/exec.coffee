# Deal with repeated execution
fs   = require 'fs'
exec = require('child_process').exec
path = require 'path'

# Keep track of running and cache for changed
running = false
changedFiles = []

# Watch a target, whether file or folder
watchTarget = (name, targets, cliInput) ->
  quiet = cliInput.options['--quiet']
  console.log "Watching file: #{name}"
  for target in targets
    fs.watchFile path.normalize(target), {interval: 100}, (e, fn) ->
      changedFiles.push fn if fn
      if not running and fn
        running = true; changedFiles = [fn]
        console.log 'Triggered by: [' if not quiet
        exec "#{cliInput.cmd}", (err, stdout, stderr) ->
          if not quiet
            console.log "#{changedFiles.reduce ((a,c) -> "#{a}    #{c}\n"), ''}]\n"
          process.stdout.write stdout
          if stderr != ''
            process.stdout.write ' >> stderr below'
            process.stderr.write stderr
          setTimeout (-> running = false), parseInt(cliInput.options['--time'],10)

module.exports = {
  watchTarget: watchTarget
}
