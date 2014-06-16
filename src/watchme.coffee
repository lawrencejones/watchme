#!/usr/bin/env coffee
# Watcher scripts. Driving me nuts with inotify bollocks
# TODO - Add support for recursive regex matching
# TODO - Add support for live updates of folders
#        This could be done by detecting all folders, hashing
#        a list of all the folders within them and on each change
#        we detect a change in the hash, and refind all subfiles

fs    = require 'fs'
path  = require 'path'
spawn = require './spawn'
Cli   = require './cli'
usage = require './usage'

# Reformat args
args = process.argv[2..]

try

  parsed = Cli.sanitize args
  [cmd, targets, options] =
    [parsed.cmd, parsed.targets, parsed.options]

  # Check for terminating flags
  if options['help']
    do usage; process.exit 0
  if options['version']
    pkgSrc = path.join __dirname, '..', 'package.json'
    pkg = JSON.parse fs.readFileSync(pkgSrc, 'utf8')
    console.log '\n    Watchme - CoffeeScript'
    console.log   "    #{pkg.description}"
    console.log   "    VERSION #{pkg.version}\n"

  # Watch targets
  for arg in targets
    spawn.watchTargetArg arg, options

catch err

  # Prefix error and print usage
  process.stdout.write '\n    -> '
  console.log err
  usage err



     
