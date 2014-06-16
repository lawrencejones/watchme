# vi: set foldmethod=marker

fs = require 'fs'
path = require 'path'
assert = require 'assert'
exec = (require 'child_process').exec
Nodes = require '../src/nodes'
CmdParser = require '../src/cmd_parser'

# Parser Spec ########################################################

describe 'CmdParser', ->

  describe 'should parse', ->

    parse = (cmd) ->
      CmdParser.parse cmd, Nodes

    it 'echo hello', ->
      echo = parse 'echo hello'
      echo.type.should.eql 'Cmd'
      echo.bin.should.eql 'echo'
      echo.args.should.eql ['hello']

    it '/usr/bin/echo hello', ->
      echo = parse '/usr/bin/echo hello'
      echo.type.should.eql 'Cmd'
      echo.should.containDeep
        bin: '/usr/bin/echo', args: ['hello']

    it 'echo hello > file', ->
      redir = parse 'echo hello > file'
      redir.type.should.eql 'RedirectOp'
      redir.src.type.should.eql 'Cmd'
      redir.src.should.containDeep
        bin: 'echo', args: ['hello']

    it "echo hello | sed 's/hello/world/g'", ->
      piped = parse "echo hello | sed 's/hello/world/g'"
      piped.type.should.eql 'PipeOp'
      piped.l.type.should.eql 'Cmd'
      piped.l.should.containDeep
        bin: 'echo', args: ['hello']
      piped.r.type.should.eql 'Cmd'
      piped.r.should.containDeep
        bin: 'sed', args: ["'s/hello/world/g'"]

    it 'echo this; echo then that', ->
      seq = parse 'echo this; echo then that'
      seq.type.should.eql 'SeqOp'
      seq.h.type.should.eql 'Cmd'
      seq.h.should.containDeep
        bin: 'echo', args: ['this']
      seq.t.type.should.eql 'Cmd'
      seq.t.should.containDeep
        bin: 'echo', args: ['then', 'that']

    it 'echo this && echo and that', ->
      conj = parse 'echo this && echo and that'
      conj.type.should.eql 'ConjunctionOp'
      conj.h.type.should.eql 'Cmd'
      conj.h.should.containDeep
        bin: 'echo', args: ['this']
      conj.t.type.should.eql 'Cmd'
      conj.t.should.containDeep
        bin: 'echo', args: ['and', 'that']


