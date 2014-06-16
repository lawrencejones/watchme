# vi: set foldmethod=marker

fs = require 'fs'
path = require 'path'
assert = require 'assert'
exec = (require 'child_process').exec
Cli = require '../src/cli'


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
  exec "rm -rf #{TMP_DIR}", -> do done

# CLI Parser Specs ###################################################

describe 'Cli', ->

  describe 'ArgParser', ->

    argParser = new Cli.ArgParser [
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
      do touch = (files = tmpFiles[..]) ->
        return done() if files.length is 0
        file = files.shift()
        fs.writeFile file, "Content of file #{file}", 'utf8', (err) ->
          if err then should.fail err
          touch files

    # Cleanup temporary files
    afterEach ->
      fs.unlinkSync file for file in tmpFiles

    # Function stub to mock our current working directory
    fileValidation = (file) ->
      Cli.ArgParser::fileExists file, TMP_DIR
    parse = (argStr) ->
      parsed = argParser.parse argStr.split(' '), fileValidation
      [parsed, parsed.options, parsed.unmatched] # [options, unmatched]


    describe 'should detect from', ->

      describe (argStr = "./file_a ./folder/file_b -c --time 1000"), ->

        parsed = options = unmatched = null
        beforeEach ->
          [parsed, options, unmatched] = parse argStr

        it 'options', ->
          options.clear.should.be.true
          options.time.should.equal 1000

        it 'unmatched', ->
          unmatched.should.be.ok
          unmatched.should.containEql './file_a', './folder/file_b'

      describe (argStr = "--clear ./file_a --regex .coffee$"), ->

        parsed = options = unmatched = null
        beforeEach ->
          [parsed, options, unmatched] = parse argStr

        it 'options', ->
          options.clear.should.be.true
          options.regex.should.eql '.coffee$'

        it 'unmatched', ->
          unmatched.should.be.ok
          unmatched.should.containEql './file_a'

    describe 'should throw error', ->

      it 'when given no arguments', ->
        try argParser.parse []
        catch err then return
        fail 'failed to throw error on no arguments'
      



