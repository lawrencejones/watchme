spawn = (require 'child_process').spawn
fs = require 'fs'
$q = require 'q'

class Node
  pipe: ->

class Sequential extends Node

  constructor: (@h, @t) ->

  init: (@def = $q.defer()) ->

    do @h.init
    @h.catch @def.reject if @firstFail
    @h.done.then =>
      @t.init @def
      @t.pipe @io

    @done = @def.promise

  pipe: (io) ->
    @io =
      sout: io.sout ? process.stdout
      serr: io.serr ? process.stderr
    @h.pipe @io

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

# Basic design pattern for a syntax node.
#
#   init: (@def, io)
#     @def: deferred object saved onto the instance
#     io:
#       in: source stream to pipe into a stdin
#       sout: destination to pipe any appropriate stdout
#       serr: destination for piping appropriate stderr


module.exports =

  Cmd: class Cmd extends Node

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

  PipeOp: class PipeOp extends Node

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
      
  SeqOp: class SeqOp extends Sequential
    firstFail: false

  ConjunctionOp: class ConjunctionOp extends Sequential
    firstFail: true

  FileNode: class FileNode extends Node
    constructor: (@file) ->
      try @writeable = fs.createWriteStream @file
      catch err then throw err
    remove: ->
      try fs.unlinkSync @file
      catch err

  RedirectOp: class RedirectOp extends Redirect
    replace: true
  AppendOp: class AppendOp extends Redirect
    replace: false


      
