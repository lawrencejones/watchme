# Deals with parsing input to the command line

fs = require 'fs'
path = require 'path'
spawn = require './spawn'

# List of command line options, in format [SHORT, FLAG, DEFAULT]
# If an option is just a boolean switch, then the option will be
# assumed false unless provided in arguments, when it's detection
# will indicate true.
#
# If an argument is expected to take a particular value, then
# give a default in as the third array element. Type is then
# inferred during parsing.
defaultOptionDefs = -> [
  ['c', 'clear']
  ['h', 'help']
  ['v', 'version']
  ['d', 'hidden']
  ['q', 'quiet']
  ['t', 'time', 1500]
  ['i', 'regex', null]
  ['e', 'exec', null]
]

# Given a string value and a default, will return the type coerced
# value of the string.
coerce = (val, def) ->
  switch typeof def
    when 'number' then parseFloat val, 10
    when 'boolean' then "#{val}" is 'true'
    else val

class ArgParser

  # Construct an instance of Options from an array of string defs.
  constructor: (defs = do defaultOptionDefs) ->
    @generateParsers defs # create argument parsers

  # Given a list of option definitions, in the form of strings
  # representing the SHORT,FLAG,VAL? of the option.
  # An example would be -c,--clear for clear, with no value, while
  # a regex option is -r,--regex,VAL to indicate that this flag has
  # an assigned value.
  #
  # The returned parsers object should have appropriate parser
  # functions for each of the supplied definitions, referenced at
  # both their short and long flag names.
  generateParsers: (defs = optDefs) ->
    @parsers = new Object
    defs.map (def) =>
      [short, long, hasDefault] = def
      @parsers["-#{short}"] = @parsers["--#{long}"] = (args, i) ->
        opt = key: long
        opt.value = coerce args[i+1], hasDefault if hasDefault != undefined
        opt
    @parsers

  # Verifies that a file exists using the supplied wd and resolving all
  # ., .. and ~'s.
  fileExists: (file, wd = process.cwd()) ->
    fpath = path.resolve wd, file
    fs.existsSync fpath

  # Given an array of command line arguments and an options
  # object, will use the objects PARSERS to process each argument
  # and assigned value in turn.
  #
  # Will return an object containing all options and unmatched
  # args.
  parse: (args, verify = @fileExists, options = {}, i = 0) ->
    # Verify argument arity
    throw new Error 'No given arguments' unless args.length > 0
    [targets, options] = [[],{}]
    while i < args.length
      opt = @parsers[args[i]]? args, i
      if !opt then targets.push args[i]
      else
        options[opt.key] = opt.value ? true
      i += 1 + +(opt?.value?)
    options: options, unmatched: targets.filter (t) -> verify t

module.exports = Cli =
  ArgParser: ArgParser
  sanitize: (args = process.argv[2..], verify) ->

    # Parse options from arguments
    argParser = new ArgParser
    parsed = argParser.parse args, verify
    [options, unmatched] = [parsed.options, parsed.unmatched]
    
    # Set up max and min number of targets
    if not unmatched.length > 0
      throw new Error 'Did not supply any valid watch targets'

    # Require a command
    if not (cmd = options['exec'])?
      throw new Error 'Command (--exec) not supplied'

    if options['clear'] then cmd = "clear; #{cmd}"

    # Return a joined command, an array of target names and reliances and
    # a hash of chosen options
    cmd: cmd
    targets: unmatched
    options: options

