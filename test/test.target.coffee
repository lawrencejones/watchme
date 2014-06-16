# vi: set foldmethod=marker

fs = require 'fs'
path = require 'path'
assert = require 'assert'
exec = (require 'child_process').exec
Targets = require '../src/targets'
[Target, File, Dir] = [Targets.Target, Targets.File, Targets.Dir]

# Modify String for semantic coloring
(require 'colorize')(String)

# Shared test hooks ##################################################

TMP_DIR = (require './test.tmpdir').init(before, after)

# Target Specs #######################################################

describe 'Target', ->

  # List of files to be created and destroyed for each test
  files = seedFiles = [
    'file_a'
    'file_b'
    'folder/file_c'
    'folder/sub_folder/file_d'
    'folder/sub_folder/sub_sub/file_e'
  ]

  tmpFiles =
    (require './test.tmpfiles').init beforeEach, afterEach, seedFiles

  describe 'File', ->

    absoluteFiles = files.map (f) -> path.join TMP_DIR, f

    it 'should reject files that do not exist', ->
      try file = new File 'bogus'
      catch err then return if /does not exist/.test err
      done 'failed to detect non-existant file'

    it 'should successfully new valid file', ->
      for file,i in files
        new File file, absoluteFiles[i], TMP_DIR

    describe 'should trigger on', ->

      absoluteFiles.map (absoluteFile,i) ->

        target = null
        beforeEach ->
          target = Target.create "./#{files[i]}", TMP_DIR
          do target.watch
        afterEach ->
          do target.unwatch
      
        describe "./#{files[i]}".white, ->
          it 'change', (done) ->
            unreg = target.subscribe (event) ->
              try
                event.tname.should.eql "./#{files[i]}"
                event.files["./#{files[i]}"].should.eql
                  type: 'change', file: absoluteFile
                count = target.waiters.length
                do unreg
                target.waiters.length.should.eql count-1
              catch err
              done err
            fs.appendFile absoluteFile, 'APPEND', 'utf8', (err) ->
              if err then done "failed to append to file #{file}"

  describe 'Dir', ->

    dirs = do ->
      _dirs = {}
      _dirs[path.dirname file] = true for file in files
      Object.keys _dirs

    absoluteDirs = dirs.map (d) -> path.join TMP_DIR, d

    it 'should reject non-existant directory', ->
      try dir = new Dir 'bogus', TMP_DIR
      catch err then return if /does not exist/.test err
      throw err

    it 'should successfully new valid directory', ->
      for dir,i in dirs
        target = Target.create dir, TMP_DIR

    describe "for #{'./folder'.white}", ->

      target = null
      tmpTarget = path.join TMP_DIR, 'folder'
      targetName = './folder'
      before ->
        target = Target.create targetName, TMP_DIR

      beforeEach ->
        do target.watch
      afterEach ->
        do target.unwatch

      it 'should detect child dir', ->
        target.should.containEql
          tname: targetName
          file: tmpTarget
          base: TMP_DIR
        Object.keys(target.subDirs).length.should.eql 1
        target.subDirs['sub_folder'].should.containEql
          tname: 'folder/sub_folder'
          file: path.join TMP_DIR, 'folder/sub_folder'
          base: TMP_DIR
        target.subDirs['sub_folder'].subDirs['sub_sub']
        .should.containEql
          tname: 'folder/sub_folder/sub_sub'
          file: path.join TMP_DIR, 'folder/sub_folder/sub_sub'
          base: TMP_DIR

      it "should detect change to #{'./folder/file_c'.white}", (done) ->
        fileC = path.join TMP_DIR, 'folder', 'file_c'
        unreg = target.subscribe (event) ->
          try
            event.should.containEql
              tname: targetName
              files:
                'folder/file_c':
                  type: 'rename', file: fileC
            count = target.waiters.length
            do unreg
            target.waiters.length.should.eql count-1
          catch err
          done err
        fs.appendFile fileC, 'APPEND', 'utf8', (err) ->
          if err then done err


