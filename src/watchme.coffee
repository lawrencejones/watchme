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

module.exports = class Watchme

  # Given a compiled command and a verbose option, will run that command.
  @run: (cmd, event, options) ->
    do console.log
    process.stdout.write '\u001B[2J\u001B[0;0f' if options['clear']
    console.log """
    Triggered by...
      [
    #{('    '+e.type+'\t'+e.file for own _,e of event.files).join '\n'}
      ]""" if event? and not options['quiet']
    do console.log
    cmd.run().then (code) ->
      console.log "\nExited with code [#{code}]" if not options['quiet']


  # Given a command in string form, with watch targets and an options config
  # will schedule that command to run on changes to targets.
  @watchTargetAndRun: (cmdStr, args, options) ->
    cmd = CmdParser.parse cmdStr, Nodes
    running = false
    targets = args.map (arg) -> Target.create arg, undefined, options['time']
    for target,i in targets
      target.watch()
      console.log "Watching #{args[i]}" if not options['quiet']
      target.subscribe (event) ->
        return if running
        running = true
        Watchme.run cmd, event, options
        .then -> running = false
    return unwatch = ->
      for target in targets
        target.unwatch()

  @startCli: (args) ->

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

      # Start watcher
      Watchme.watchTargetAndRun cmdStr, targets, options

    catch err

      # Prefix error and print usage
      process.stdout.write '\n    -> '
      console.log err
      usage err

      throw err


if not module.parent
  Watchme.startCli process.argv[2..]
