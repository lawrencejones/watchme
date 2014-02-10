# Deals with outputting usage

fs   = require 'fs'
path = require 'path'

module.exports = printUsage = (error) ->
  "Error\n#{error}"
  readme = fs.readFileSync(path.join(__dirname, '..', 'README.md'), 'utf8')
  usage = readme.split(/#+ Usage.*\n/g)[1]
  console.log usage

