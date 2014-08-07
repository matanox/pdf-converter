

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

    arrays = filesContent.map((content) -> util.trimLast(content, '\n').split('\n')) # separate by lines

    a = arrays[0]
    b = arrays[1]

    idx = 
      a : 0
      b : 0

    console.dir arrays

    while idx.a < a.length and idx.b < b.length
      aItem = a[idx.a]
      bItem = b[idx.b]
      
      switch aItem is bItem
        when true:
          idx.a += 1
          idx.b += 1
        when false:
          if similar(aItem, bItem)
            idx.a += 1
            idx.b += 1
          else
            




        
    logging.logYellow 'after diff'

