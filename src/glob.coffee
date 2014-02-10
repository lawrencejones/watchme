fs = require 'fs'

# Generate an array of targets matched against the ptrn, recursively
globPattern = (ptrn) ->
  rexedFiles = []
  for fpath in files
    [dir, rexstr] = [path.dirname(fpath), path.basename(fpath)]
    rex = new RegExp rexstr
    for f in fs.readdirSync dir
      rexedFiles.push path.join(dir, f) if rex.test f
  files = rexedFiles

# Expand all directories into their child targets
filesInDir = (dir, includeHidden) ->
  if not fs.statSync(dir).isDirectory() then return [dir]
  dirs = [dir].concat (filesInDir(path.join(dir, f)) for f in fs.readdirSync(dir) when not /^\./.test f)
  return dirs.concat.apply([], dirs)

module.exports = {
  targetsInDir: filesInDir
  targetsOnPattern: globPattern
}
