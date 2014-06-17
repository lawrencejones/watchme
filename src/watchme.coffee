#!/usr/bin/env coffee
# Watcher scripts. Driving me nuts with inotify bollocks
# TODO - Add support for recursive regex matching
# TODO - Add support for live updates of folders
#        This could be done by detecting all folders, hashing
#        a list of all the folders within them and on each change
#        we detect a change in the hash, and refind all subfiles

fs        = require 'fs'
path      = require 'path'
usage     = require './usage'
Cli       = require './cli'
CmdParser = require './cmd_parser'
Nodes     = require './nodes'
Target    = (require './targets').Target

# Reformat args
args = process.argv[2..]

# Parse arguments
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
  process.exit 0

try

  # Set up max and min number of targets
  if not targets.length > 0
    throw new Error 'Did not supply any valid watch targets'

  # Require a command
  if not (cmdStr = options['exec'])?
    throw new Error 'Command (--exec) not supplied'

  if options['clear'] then cmdString = "clear; #{cmdStr}"

  cmd = CmdParser.parse cmdStr, Nodes
  running = false

  # Watch targets
  for arg in targets
    target = Target.create arg
    do target.watch
    console.log "Watching #{arg}"
    target.subscribe (event) ->
      if not running
        running = true
        if not options['quiet'] then console.log """
        Triggered by...
          [
        #{('    '+e.type+'\t'+e.file for own _,e of event.files).join '\n'}
          ]"""
        cmd.run().then (code) ->
          console.log "Exited with code [#{code}]" if not options['quiet']
        .finally -> running = false

catch err
  throw err

  # Prefix error and print usage
  process.stdout.write '\n    -> '
  console.log err
  usage err



     
