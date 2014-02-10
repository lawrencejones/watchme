fs   = require 'fs'
path = require 'path'

# Generate an array of targets matched against the ptrn, recursively
globPattern = (ptrn) ->
  rexedFiles = []
  for fpath in files
    [dir, rexstr] = [path.dirname(fpath), path.basename(fpath)]
    rex = new RegExp rexstr
    for f in fs.readdirSync dir
      rexedFiles.push path.join(dir, f) if rex.test f
  files = rexedFiles

module.exports = {
  targetsOnPattern: globPattern
}
