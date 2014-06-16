# Shared test hooks ##################################################
exec = (require 'child_process').exec

# Store all test files in this folder. Remove on cleanup.
TMP_DIR = "/tmp/watchme-#{Date.now()}"

module.exports =
  TMP_DIR: TMP_DIR
  init: (before, after) ->

    # Create a new tmp folder first
    before (done) ->
      exec "mkdir -p #{TMP_DIR}", (err) ->
        if err is not 0 then throw err
        do done

    # Remove the directory
    after (done) ->
      exec "rm -rf #{TMP_DIR}", -> do done

    TMP_DIR

