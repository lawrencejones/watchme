fs = require 'fs'
path = require 'path'
exec = (require 'child_process').exec
$q = require 'q'

# Get current temporary directory
TMP_DIR = (require './test.tmpdir').TMP_DIR

# Returns a unique list of directories from the array of file
# paths to construct.
getDirnames = (files, base = TMP_DIR) ->
  dirs = new Object
  for file in files
    dirs[path.dirname file] = true
  Object.keys(dirs).map (dir) -> path.join base, dir

# Attempts to create all directories required for the given
# files.
makeDirs = (files, base) ->
  $q.all getDirnames(files, TMP_DIR).map (dir) ->
    def = $q.defer()
    exec "mkdir -p #{dir}", (err) ->
      if err is not 0 then def.reject err
      else def.resolve()
    return def.promise

# Creates a file for each of the given files, containing a small
# textual placeholder.
makeFiles = (files, base = TMP_DIR) ->
  $q.all files.map (rel) ->
    def = $q.defer()
    file = path.join base, rel
    fs.writeFile file, "Content for file #{file}", 'utf8', (err) ->
      if err is not 0 then def.reject err
      else def.resolve file
    return def.promise

# Given hooks for before and after each test, along with an
# array of file paths to construct with the placeholder content
# of "This is content for file FILE".
#
# Will clean the temporary directory after every test.
module.exports =
  TMP_DIR: TMP_DIR
  init: (beforeEach, afterEach, files) ->

    # Create a new tmp folder first
    before (done) ->
      makeDirs files, TMP_DIR
      .then ->
        makeFiles files, TMP_DIR
          .then -> do done
      .catch done

    # Remove all files in directory
    after (done) ->
      exec "rm -rf #{TMP_DIR}/*", -> do done

    files.map (f) -> path.resolve TMP_DIR, f

    

