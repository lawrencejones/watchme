#!/usr/bin/env coffee
# Watcher scripts. Driving me nuts with inotify bollocks
# TODO - Add support for recursive regex matching
# TODO - Add support for live updates of folders
#        This could be done by detecting all folders, hashing
#        a list of all the folders within them and on each change
#        we detect a change in the hash, and refind all subfiles

fs    = require 'fs'
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
    do version; process.exit 0

  # Watch targets
  for t in cliInput.targets
    exec.watchTarget(t.label, t.targets, cliInput)

catch err

  # Prefix error and print usage
  process.stdout.write '\n -> '
  console.log err
  usage err



     