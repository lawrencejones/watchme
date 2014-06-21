# Callbacks will take the form of
#   (target, event) ->
# Where event can be [ rename | newfile | delete ]

fs   = require 'fs'
path = require 'path'
$q   = require 'q'

class Target

  # Given a target string, will return either an instanceof
  # Target, which can then be subscribed to for changes.
  # WD is the base from which to resolve targets.
  @create: (tname, base = process.cwd(), wait) ->
    file = path.join base, tname
    Type = if fs.statSync(file).isDirectory() then Dir else File
    new Type tname, file, base, wait

  # Supplied with a target name and a filepath, will construct
  # a Target instance.
  constructor: (@tname, @file = @tname, @base = process.cwd(), @wait = 25) ->
    @waiters = []
    @inProgress = false
    @eventCache = undefined
    if not fs.existsSync @file
      throw new Error "File #{@file} does not exists"

  # Stub to force implementation
  unwatch: ->
    throw new Error 'Unwatch should be implemented in children'

  # The supplied callback is added to the list of waiters that
  # are called whenever this node detects a change.
  # Will return either a unsubscribe function, or null to indicate
  # that an invalid callback was supplied.
  subscribe: (cb) ->
    return null if !cb || typeof cb != 'function'
    @waiters.push cb
    =>
      if (i = @waiters.indexOf cb) != -1
        return @waiters.splice i, 1

  # Triggers all subscribed callbacks with the target label and
  # all detected changes.
  # WAIT specifies how long the target should wait before calling
  # the waiters. This allows a refactory period to prevent spamming
  # of triggers.
  # The EVENT object is structured as...
  #
  #   tname:  Target moniker
  #   type:   Type of change
  #   file:   Path to file
  #
  # During the wait, extra file events can be pushed into EVENT.FILES.
  broadcast: (event) ->
    event.type = event.type.replace /rename/, 'change'
    run = not @eventCache?
    @eventCache ?= tname: @tname, files: {}
    @eventCache.files[event.tname] ?=
      type: event.type, file: event.file
    if run then $q.delay(@wait).then =>
      waiter @eventCache for waiter in @waiters
      @eventCache = undefined


# Defines a standard file target
class File extends Target

  # Starts to watch the file target for changes.
  # Whenever a change is detected, will call broadcast.
  watch: ->
    @_watch = fs.watch @file, persistant: true, (e, name) =>
      @broadcast type: e, tname: @tname, file: @file

  # Stops the current watching of the file.
  unwatch: ->
    @_watch?.close?()
    
# Manages directory structure
class Dir extends Target

  constructor: (args...) ->
    super args...
    @subDirs = new Object

  # Starts watching the directory for any changes. This means
  # triggering a broadcast whenever the folder contents, or any
  # contents within it changes.
  #
  # The fs.watch command will trigger on a change of any folder
  # contents, but any folders within our directory need to be
  # watched independently.
  watch: (base = @base) ->
    @_watch?.close()
    @_watch = fs.watch @file, persistant: true, (e, name) =>
      fname = path.join @tname, name
      fpath = path.join @file, name
      @broadcast tname: fname, type: e, file: fpath
      do @watchSubDirs
    @watchSubDirs base

  # Stops the current watching of files. Essentially calling
  # pruneSubs in the event of all being removed.
  unwatch: ->
    @_watch?.close?()
    @pruneSubs []

  # Given that we know what directory we initially represent,
  # we can now look through our contents and identify any sub
  # folders within.
  #
  # These folders then require watching on an individual basis
  # for any changes. Once they change, we should remove old
  # watchers and start watching new.
  watchSubDirs: ->
    files = fs.readdirSync @file
    @pruneSubs files
    for _child in files
      cname  = path.join @tname, _child
      cpath  = path.join @file, _child
      if fs.statSync(cpath).isDirectory()
        if not @subDirs[_child]?
          target = @subDirs[_child] ?=
            Target.create cname, @base
          do target.watch
          target.subscribe (event) =>
            for own file,change of event.files
              @broadcast\
              ( tname: @tname, type: change.type, file: change.file )

  # Examines the current folder contents. If any folder watchers
  # are registered which no longer exist, then these are removed
  # from our subwatchers.
  pruneSubs: (files = fs.readdirSync @file) ->
    for own cname,target of @subDirs
      if files.indexOf(cname) < 0
        do target.unwatch
        delete @subDirs[cname]

# Decides if delete has ocurred
determineEvent = (curr, prev) ->
  if curr.mode is 0 then return 'delete'
  return 'modify'

module.exports = Targets =
  Target: Target
  Dir: Dir
  File: File

