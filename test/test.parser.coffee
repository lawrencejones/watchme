# vi: set foldmethod=marker

fs = require 'fs'
path = require 'path'
assert = require 'assert'
exec = (require 'child_process').exec
Nodes = require '../src/nodes'
CmdParser = require '../src/cmd_parser'

# Shared test hooks ##################################################

# Store all test files in this folder. Remove on cleanup.
TMP_DIR = (require './test.tmpdir').init(before, after)
STDOUT = path.join TMP_DIR, 'stdout.log'
STDERR = path.join TMP_DIR, 'stderr.log'

# Test cases
TEST_CMDS =
  [
      #####################################################
    [ 'Cmd'
      #####################################################
      
      cmd: 'echo'
      exp: bin: 'echo', args: []
      out: '\n', err: ''
    ,
      cmd: 'echo hello world'
      exp: bin: 'echo', args: ['hello', 'world']
      out: 'hello world\n', err: ''
    ,
      cmd: 'karma start test/karma-unit.conf.coffee'
      exp: bin: 'karma', args: ['start', 'test/karma-unit.conf.coffee']
      dontExec: true
    ,
      cmd: 'touch /tmp/file'
      exp: bin: 'touch', args: ['/tmp/file']
      out: '', err: ''
    ,
      cmd: '/bin/echo'
      exp: bin: '/bin/echo', args: []
      out: '\n', err: ''
    ]
      #####################################################
    [ 'SeqOp'
      #####################################################
      
      cmd: 'echo first; echo second'
      exp:
        head: bin: 'echo', args: ['first']
        tail: bin: 'echo', args: ['second']
      out: 'first\nsecond\n', err: ''
    ,
      cmd: 'echo; echo last'
      exp:
        head: bin: 'echo', args: []
        tail: bin: 'echo', args: ['last']
      out: '\nlast\n', err: ''
    ,
      cmd: ';echo'
      exp:
        head: {}
        tail: bin: 'echo', args: []
      out: '\n', err: ''
    ]
      #####################################################
    [ 'ConjOp'
      #####################################################
      
      cmd: 'echo this && echo and'
      exp:
        head: bin: 'echo', args: ['this']
        tail: bin: 'echo', args: ['and']
      out: 'this\nand\n', err: ''
    ,
      cmd: 'which /does/not/exist && echo donotprint'
      exp:
        head: bin: 'which', args: ['/does/not/exist']
        tail: bin: 'echo', args: ['donotprint']
      out: '', err: '', exit: 1
    ]
      #####################################################
    [ 'PipeOp'
      #####################################################
      
      cmd: "echo hello | sed s/hello/world/g"
      exp:
        lhs: bin: 'echo', args: ['hello']
        rhs: bin: 'sed', args: ['s/hello/world/g']
      out: 'world\n', err: ''
    ]
#     #####################################################
#   [ 'RedirectOp' # TODO
#     #####################################################
#
#     cmd: "echo CONTENT > #{TMP_DIR}/output; cat #{TMP_DIR}/output"
#     exp:
#       head:
#         src: bin: 'echo', args: ['hello']
#         dst: file: "#{TMP_DIR}/output"
#       tail:
#         bin: 'cat', args: ["#{TMP_DIR}/output"]
#     out: 'CONTENT', err: '', rootType: 'SeqOp', circular: true # fix this
#   ]
  ]

# Parser Spec ########################################################

describe 'CmdParser', ->

  TEST_CMDS.map (nodeClass) ->

    [node, tests...] = nodeClass

    describe "#{node} Node", ->

      [stdout, stderr] = [null, null]
      beforeEach ->
        stdout = fs.createWriteStream STDOUT
        stderr = fs.createWriteStream STDERR
        stdout.encoding = stderr.encoding = 'utf8'

      afterEach (done) ->
        fs.unlink STDOUT, (err) -> fs.unlink STDERR, (err) -> do done

      verifyLogs = (eout, eerr) ->
        fs.readFileSync(STDOUT, 'utf8').should.eql eout
        fs.readFileSync(STDERR, 'utf8').should.eql eerr

      tests.map (test) ->

        cmd = null
        [cmdStr, exp, eout, eerr] = [test.cmd, test.exp, test.out, test.err]
        exit = test.exit ? 0

        describe "$ #{cmdStr}".white, ->

          describe 'should', ->

            it 'parse', ->
              cmd = CmdParser.parse cmdStr, Nodes
              cmd.type.should.eql test.rootType if test.rootType
              cmd.should.eql exp if not test.circular

            if not test.dontExec then it 'execute', (done) ->
              cmd.run(stdout, stderr).then (code) ->
                code.should.be.eql exit
                verifyLogs eout, eerr
                do done
              .catch done
              .done()






