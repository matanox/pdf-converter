fs          = require 'fs'
util        = require '../util/util'
logging     = require '../util/logging' 
jsdiff      = require 'diff' # https://github.com/kpdecker/jsdiff

docsDataDir = require('../data/dataWriter').docsDataDir

#
# gets the pair of files to compare
#
getPair = (inputFileName, dataType) ->

  docDataDir = docsDataDir + '/' + inputFileName + '/'

  relevantDataFiles = fs.readdirSync(docDataDir).filter((dataFileName) -> dataFileName.indexOf(dataType) is 0)

  if relevantDataFiles.length > 1
    relevantDataFiles.sort().reverse() 
    return relevantDataFiles.slice(0, 2).map((dataFileName) -> docDataDir + dataFileName) # slice first two items, create full path

  return undefined

exports.diff = (inputFileName, dataType) ->

  logging.logYellow 'before diff'

  pair = getPair(inputFileName, dataType)
  if pair?
    filesContent = pair.map((file) -> 
      fs.readFileSync(file, {encoding: 'utf8'}))

    console.log filesContent[0]
    console.log filesContent[1]

    jsdiff.diffLines(filesContent[0], filesContent[1]).forEach((line) -> console.log line)
    logging.logYellow 'after diff'

