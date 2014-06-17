spawn = (require 'child_process').spawn
fs = require 'fs'
$q = require 'q'

# Main Parent Node ###################################################

class Node
  run: (@out = process.stdout, @err = process.stderr) ->
  pipe: (sout, serr) ->
    sout?.pipe @out, end: false
    serr?.pipe @err, end: false

class NoOp extends Node
  type: 'NoOp'
  run: -> $q.fcall -> 0

# Basic Command, Simulates a Program #################################

class Cmd extends Node

  type: 'Cmd'
  constructor: (@bin, @args) ->

  run: (args...) ->
    super args...
    prog = spawn @bin, @args
    @pipe prog.stdout, prog.stderr
    @in = prog.stdin
    def = $q.defer()
    prog.on 'close', (code) =>
      def.resolve code
    def.promise

# Command Composition - Sequential ;, && ###############################

class Composition extends Node
  constructor: (@head, @tail) ->

class SeqOp extends Composition
  type: 'SeqOp'
  run: (args...) ->
    super args...
    @head.run(@out, @err).then =>
      @tail.run(@out, @err)

class ConjOp extends Composition
  type: 'ConjOp'
  run: (args...) ->
    super args...
    @head.run(@out, @err).then (code) =>
      code || @tail.run(@out, @err)

# Command Output Redirect to File > ##################################

class Redirect extends Node

  constructor: (@src, @dst) ->
    if not @dst instanceof FileNode
      throw new Error """
      Destination must be an instance of FileNode"""

  run: (args..., append) ->
    super args...
    done = @src.run()
    do @dst.open
    @dst.remove() if @ instanceof RedirectOp
    @src.out?.pipe @dst.in, end: false
    @src.err?.pipe @dst.in, end: false
    done

class RedirectOp extends Redirect
  type: 'RedirectOp'
  replace: true
class AppendOp extends Redirect
  type: 'AppendOp'
  replace: false

# Process Piping | ###################################################

class PipeOp extends Node

  type: 'PipeOp'
  constructor: (@lhs, @rhs) ->

  run: (args...) ->
    super args...
    rhsDone = @rhs.run @out, @err
    lhsDone = @lhs.run @rhs.in, @rhs.in
    @in = @lhs.in

    lhsDone.then rhsDone

# File Writeable Node ################################################

class FileNode extends Node
  type: 'FileNode'
  constructor: (@file) ->
  open: ->
    try @in = fs.createWriteStream @file
    catch err then throw err
  remove: ->
    try fs.unlinkSync @file
    catch err
  close: -> @in?.end?()


module.exports = Nodes =

  Node: Node
  NoOp: NoOp
  Cmd: Cmd
  FileNode: FileNode

  # Piping
  PipeOp: PipeOp

  # Composition
  Composition: Composition
  SeqOp: SeqOp
  ConjOp: ConjOp

  # Redirects
  Redirect: Redirect
  RedirectOp: RedirectOp
  AppendOp: AppendOp

