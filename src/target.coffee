# Callbacks will take the form of
#   (target, event) ->
# Where event can be [ rename | newfile | delete ]

fs   = require 'fs'
path = require 'path'
glob = require './glob'

# Store all watched targets
targets = []

# Track if verbose is on
verbose = false

# Debug only if not quiet
debug = (mssg, newline = true) ->
  mssg = "#{mssg}\n" if newline
  process.stdout.write mssg if verbose

# Creates correct target
createTarget = (label, basename, hidden, cb) ->
  try
    st = fs.statSync path.normalize(label)
  catch err
    throw new Error("File handle [#{@label}] not found")
  Target = if st.isDirectory() then Dir else File
  new Target(label, basename, hidden, cb)

# Manages targets by continually updating the tree
class Target

  constructor: (label, @basename, @cb) ->
    target = this
    debug "Watching file: #{label}"
    @label = path.normalize label

  stat: -> fs.statSync @label

  unwatch: ->
    debug "Unwatching #{@label}"
    fs.unwatchFile @lis

# Manages directory structure
class Dir extends Target

  constructor: (label, basename, @hidden, cb) ->
    dir = this
    @children = {}
    super label, basename, cb
    if not @stat().isDirectory()
      throw new Error("Handle [#{@label}] is not a directory")
    @watchChildren true
    # Watches for changes on this directory
    @lis = fs.watch @label, {interval: 100}, ->
      added = dir.watchChildren.call(dir)
      for target in added
        e = if target.stat().isDirectory() then 'newdir' else 'newfile'
        target.cb target, e
    @delLis = fs.watchFile @label, {interval: 100}, (curr, prev) ->
      if curr.mode is 0 then dir.unwatch.call dir

  listChildren: ->
    label = @label
    files = fs.readdirSync(@label).map (f) ->
      path.normalize(path.join label, f)
    if not @hidden
      return files.filter (f) -> not /^\..+/.test path.basename(f)
    files

  watchChildren: ->
    added = []
    for fn in do @listChildren
      if not @children[fn]?
        added.push (@children[fn] = createTarget fn, @basename, @cb)
    debug "Updating #{@label}: [#{added.map((a)->a.label).join(', ')}]"
    do @pruneChildren
    return added

  pruneChildren: ->
    files = @listChildren()
    [exist, deleted] = Object.keys(@children).reduce ((a,c) ->
      a[+(files.indexOf(c) == -1)].push c; a
    ), [[],[]]
    for lbl in deleted
      @children[lbl].unwatch.call(@children[lbl])
      delete @children[lbl]
    debug "Pruning #{@label}: [#{deleted.join(', ')}]"

  unwatch: ->
    for own lbl, target of @children
      target.unwatch()
    @cb @, 'deldir'
    super

# Decides if delete has ocurred
determineEvent = (curr, prev) ->
  if curr.mode is 0 then return 'delete'
  return 'modify'

# Defines a standard file target
class File extends Target
  constructor: (args...) ->
    super args...
    file = this
    @lis = fs.watchFile @label, {interval: 100}, (curr,prev) ->
      e = determineEvent curr, prev
      file.cb file, e, file.label


module.exports = {
  Dir: Dir
  File: File
  create: createTarget
}

