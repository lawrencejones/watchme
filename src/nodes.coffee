spawn = (require 'child_process').spawn
fs = require 'fs'
$q = require 'q'

# Main Parent Node ###################################################

class Node
  pipe: ->

# Basic Command, Simulates a Program #################################

class Cmd extends Node

  type: 'Cmd'
  constructor: (@bin, @args) ->

  init: (@def = $q.defer()) ->
    @prog = spawn @bin, @args
    @prog.on 'close', (code) =>
      if !code? or code is 0
        return @def.resolve 0
      else @def.reject code
    @done = @def.promise

  pipe: (io) ->
    io.in?.pipe @prog.stdin if io.in?
    @prog.stdout?.pipe io.sout if io.sout?
    @prog.stderr?.pipe io.serr if io.serr?

# Command Composition - Sequential ;, && ###############################

class Sequential extends Node

  constructor: (@h, @t) ->

  init: (@def = $q.defer()) ->

    do @h.init
    @h.done.catch @def.reject if @firstFail

    # Determine whether to proceed with next command on failure, or fail.
    handler = @h.done[if @firstFail then 'then' else 'finally']
    handler.call @h.done, =>
      @t.init @def
      @t.pipe @io

    @done = @def.promise

  pipe: (io) ->
    @io =
      sout: io.sout ? process.stdout
      serr: io.serr ? process.stderr
    @h.pipe @io

class SeqOp extends Sequential
  type: 'SeqOp'
  firstFail: false

class ConjunctionOp extends Sequential
  type: 'ConjunctionOp'
  firstFail: true

# Command Output Redirect to File > ##################################

class Redirect extends Node

  constructor: (@src, @dst) ->
  
  init: (@def = $q.defer()) ->
    do @src.init
    @dst.remove() if @replace
    @src.pipe sout: @dst.writeable, serr: @dst.writeable
    @src.done.catch @def.reject
    @src.done.then @def.resolve
    @src.done.finally =>
      @dst.writeable.end()
    @done = @def.promise

class RedirectOp extends Redirect
  type: 'RedirectOp'
  replace: true
class AppendOp extends Redirect
  type: 'AppendOp'
  replace: false

# Process Piping | ###################################################

class PipeOp extends Node

  type: 'PipeOp'
  constructor: (@l, @r) ->

  init: (@def = $q.defer()) ->

    do @l.init
    @recv = @l.recv
    do @r.init @def

    @l.pipe sout: @r.recv, serr: @r.recv
    @l.done.then => @r.recv.end()
    @l.done.catch @def.reject

    @done = @def.promise

  pipe: (io) ->
    @l?.pipe? in: io.in, sout: @r.recv, serr: process.stderr
    @r?.pipe? sout: io.sout, serr: io.serr
    
# File Writeable Node ################################################

class FileNode extends Node
  type: 'FileNode'
  constructor: (@file) ->
  open: ->
    try @writeable = fs.createWriteStream @file
    catch err then throw err
  remove: ->
    try fs.unlinkSync @file
    catch err


module.exports = Nodes =

  Node: Node
  Cmd: Cmd
  FileNode: FileNode

  # Piping
  PipeOp: PipeOp

  # Sequentials
  Sequential: Sequential
  SeqOp: SeqOp
  ConjunctionOp: ConjunctionOp

  # Redirects
  Redirect: Redirect
  RedirectOp: RedirectOp
  AppendOp: AppendOp

