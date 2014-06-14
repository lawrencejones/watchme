# Deals with parsing input to the command line

path = require 'path'
glob = require './glob'
spawn = require './spawn'

# List of command line options
optAliases = {
  c: '--clear'
  h: '--help'
  v: '--version'
  i: '--regex'
  d: '--hidden'
  t: '--time'
  e: '--exec'
  q: '--quiet'
}

defaultOptions = -> {
  '--time':   1500
  '--clear':  false
  '--regex':  false
  '--quiet':  false
  '--hidden': false
}

# Loop back aliases
(_opts = _opts || {})["-#{k}"] = v for k,v of optAliases
_opts[v] = v for own k,v of _opts
optAliases = _opts
  
# Extract a --flag <value> pair
extractFlagValue = (args, flag, short) ->
  if not /^(\-\w)|(\-\-\w+)$/.test flag
    throw new Error("Invalid flag: #{flag}")
  short = short || flag.match(/\-(\w)/)[1]
  long  = flag.match(/\-\-(\w+)/)[1]
  r = new RegExp("^(\-#{short}|\-\-#{long})$")
  for arg,i in args
    if r.test arg
      [_, val] = args.splice(i, 2)
      return val

# Return a hash of option switches
parseOptions = (args) ->

  # Assign default options initially
  options = do defaultOptions
  
  # Set up max and min number of targets
  [targetMin, targetMax] = [1,10]
  
  # Verify argument arity
  if args.length is 0
    process.stderr.write 'No given arguments\n'
    throw new Error('No arguments')

  # Remove --exec and "cmd" from args
  cmd = extractFlagValue(args, '--exec') || ''
  spawn.validateCmd cmd # may throw error

  # Parse the time delay
  options['--time'] = extractFlagValue(args, '--time') || options['--time']

  # Split array into valid and invalid targets
  [valid, invalid, targets] = args.reduce ((v,c) ->
    v[+(!optAliases[c]?) + +(not /\-.+/.test(c))].push c; v), [[],[],[]]
    
  # If any invalid throw error
  if invalid.length != 0
    throw new Error("Invalid arguments: #{invalid}")
  
  # Parse selected options
  options[optAliases[f]] = true for f in valid

  # If regex then glob targets
  # if options['--regex']
  #   try
  #     files = (glob.targetsOnPattern new RegExp(file) for file in files)
  #   catch err
  #     throw new Error('Invalid regular expression, conform to ECMA standards')
  
  # Add a clear
  if options['--clear'] then cmd = "clear; #{cmd}"

  # Return a joined command, an array of target names and reliances and
  # a hash of chosen options
  return {
    cmd: cmd
    targetArgs: targets
    options: options
  }

module.exports = parseOptions
