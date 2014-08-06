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

#
# pad input string with an extra new line, between each of its lines
#
pad = (string) ->
  trimmed = util.trim(string, '\n') # discard last \n
  return string.split('\n').join('\n\n') # add newline after each newline
  
exports.diff = (inputFileName, dataType) ->

  logging.logYellow 'before diff'

  pair = getPair(inputFileName, dataType)
  if pair?
    filesContent = pair.map((file) -> 
      fs.readFileSync(file, {encoding: 'utf8'}))

    console.log filesContent[0]
    console.log filesContent[1]

    #paddedContent = filesContent.map(pad)

    # get differences
    rawDiff = jsdiff.diffLines(filesContent[0], filesContent[1]).filter((diffDescriptor) -> 
        diffDescriptor.added or diffDescriptor.removed) 

    # expand diff entries that contain multiple lines, producing a finer diffs array

    console.dir rawDiff

    diffs = []
    rawDiff.forEach((diffDescriptor) -> 
      # split while removing \n 
      diffDescriptor.value = util.trim(diffDescriptor.value, '\n')
      splits = diffDescriptor.value.split('\n')
      splits.forEach((split) -> 
        split.added   = diffDescriptor.added
        split.removed = diffDescriptor.removed
        diffs.push split
      )
        
    )

    console.dir diffs

    logging.logYellow 'after diff'

