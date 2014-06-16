# Hook to allow coffee execution of the pegjs parser.
fs   = require 'fs'
peg  = require 'pegjs'

path = require 'path'

try grammar = fs.readFileSync (path.join __dirname, 'grammar.pegjs'), 'utf8'
catch err
  console.log 'No grammar.pegjs file found!'
  throw err

try parser = peg.buildParser grammar
catch err
  console.log 'Failed to compile grammar.pegjs using pegjs'
  throw err

module.exports = parser
