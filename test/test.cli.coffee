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
TMP_DIR = "/tmp/watchme-#{Date.now()}"

# Create a new tmp folder first
before (done) ->
  exec "mkdir -p #{TMP_DIR} #{TMP_DIR}/folder", (err) ->
    if err is not 0 then throw err
    do done

# Remove the directory
after (done) ->
  console.log TMP_DIR
  exec "rm -rf #{TMP_DIR}", -> do done

# CLI Parser Specs ###################################################

describe 'Cli', ->

  describe 'ArgParser', ->

    argParser = new Cli.ArgParser [# {{{
      ['c', 'clear']
      ['t', 'time', 1500] # default 1500
      ['r', 'regex', null]
    ]

    tmpFiles = [
      'file_a'
      'folder/file_b'
    ].map (file) -> path.join TMP_DIR, file

    # Create temp test files
    beforeEach (done) ->
      do touch = (files = tmpFiles[..]) -># {{{
        return done() if files.length is 0
        file = files.shift()
        fs.writeFile file, "Content of file #{file}", 'utf8', (err) ->
          if err then should.fail err
          touch files# }}}

    # Cleanup temporary files
    afterEach ->
      fs.unlinkSync file for file in tmpFiles

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

    describe 'should throw error', ->

      it 'when given no arguments', -># {{{
        try sanitize []
        catch err then return
        throw Error 'failed to throw error on no arguments'

      it 'when no exec command given', ->
        try sanitize ['./file_a', '--clear']
        catch err then return
        throw Error 'failed to detect no exec'# }}}
      # }}}




