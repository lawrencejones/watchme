# vi: set foldmethod=marker

fs = require 'fs'
path = require 'path'
assert = require 'assert'
exec = (require 'child_process').exec
Cli = require '../src/cli'

# Modify String for semantic coloring
(require 'colorize')(String)

# Shared test hooks ##################################################

# Store all test files in this folder. Remove on cleanup.
TMP_DIR = (require './test.tmpdir').init(before, after)

# CLI Parser Specs ###################################################

describe 'Cli', ->

  describe 'ArgParser', ->

    argParser = new Cli.ArgParser [
      ['c', 'clear']
      ['t', 'time', 1500] # default 1500
      ['r', 'regex', null]
    ]

    files = [
      'file_a'
      'folder/file_b'
    ]

    # Setup automatical tmp folder generation
    (require './test.tmpfiles').init(beforeEach, afterEach, files)

    # Function stub to mock our current working directory
    fileValidation = (file) ->
      Cli.ArgParser::fileExists file, TMP_DIR
    parse = (args) ->
      parsed = argParser.parse args, fileValidation
      [parsed, parsed.options, parsed.unmatched] # [options, unmatched]
    sanitize = (args) ->
      Cli.sanitize args, fileValidation

    # Pair of tests for argument parsing
    testArgs = [firstArgs, secondArgs] = [
      [ './file_a', './folder/file_b'
        '-c', '--time', '1000'
        '--exec', '"echo hello"' ]
      [ '--clear', './file_a', '--regex', '.coffee$'
        '-e', '"touch /tmp/tmp""' ]
    ]

    describe 'should detect from', ->

      describe "$ #{firstArgs.join ' '}".white, ->

        parsed = options = unmatched = null# {{{
        beforeEach ->
          [parsed, options, unmatched] = parse firstArgs

        it 'has options', ->
          options.clear.should.be.true
          options.time.should.equal 1000

        it 'unmatched', ->
          unmatched.should.be.ok
          unmatched.should.containEql './file_a', './folder/file_b'

        it 'sanitized', ->
          sanitize firstArgs# }}}

      describe "$ #{secondArgs.join ' '}".white, ->

        parsed = options = unmatched = null# {{{
        beforeEach ->
          [parsed, options, unmatched] = parse secondArgs

        it 'options', ->
          options.clear.should.be.true
          options.regex.should.eql '.coffee$'

        it 'unmatched', ->
          unmatched.should.be.ok
          unmatched.should.containEql './file_a'

        it 'sanitized', ->
          sanitize secondArgs# }}}





