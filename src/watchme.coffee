#!/usr/bin/env coffee
# Watcher scripts. Driving me nuts with inotify bollocks
# TODO - Add support for recursive regex matching
# TODO - Add support for live updates of folders
#        This could be done by detecting all folders, hashing
#        a list of all the folders within them and on each change
#        we detect a change in the hash, and refind all subfiles

fs    = require 'fs'
path  = require 'path'
exec  = require './exec'
cli   = require './cli'
usage = require './usage'

# Reformat args
args = process.argv[2..]

try

  # Parse options
  if args.length is 0
    throw new Error('No given arguments')
  cliInput = cli args

  # Check for terminating flags
  if cliInput.options['--help']
    do usage; process.exit 0
  if cliInput.options['--version']
    pkg_src = path.join __dirname, '..', 'package.json'
    pkg = JSON.parse fs.readFileSync(pkg_src, 'utf8')
    console.log '\n    Watchme - CoffeeScript'
    console.log   "    #{pkg.description}"
    console.log   "    VERSION #{pkg.version}\n"

  # Watch targets
  for arg in cliInput.targetArgs
    exec.watchTargetArg arg, cliInput

catch err
  throw err

  # Prefix error and print usage
  process.stdout.write '\n    -> '
  console.log err
  usage err



     
