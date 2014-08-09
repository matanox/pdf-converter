fs          = require 'fs'
util        = require '../util/util'
logging     = require '../util/logging' 
#jsdiff      = require 'diff' # https://github.com/kpdecker/jsdiff
dtldiff     = require 'dtl' # https://github.com/cubicdaiya/node-dtl

dataWriter  = require('../data/dataWriter')
docsDataDir = dataWriter.docsDataDir

#
# gets the pair of files to compare
#
getPair = (inputFileName, dataType) ->

  console.dir dataType

  docDataDir = docsDataDir + '/' + inputFileName + '/'

  relevantDataFiles = fs.readdirSync(docDataDir).filter((dataFileName) -> dataFileName.indexOf(dataType) is 0)

  if relevantDataFiles.length > 1
    relevantDataFiles.sort().reverse() 
    return relevantDataFiles.slice(0, 2).map((dataFileName) -> docDataDir + dataFileName) # slice first two items, create full path

  return undefined

#
# tokenize string by a given delimieter, while turning all occurences of the 
# delimiter into delimiting *tokens* in the same result array sequence.
#
rsplit = (contentArray, delimiter) ->
  newArray = []
  contentArray.forEach((contentUnit) ->
    if contentUnit.indexOf(delimiter) is -1
      newArray.push contentUnit
    else 
      # turn each delimiter occurence to being its own array element
      split = contentUnit.split(delimiter)
      split.reduce((prev, curr) -> 
        newArray.push prev, delimiter
        return curr
      )
      newArray.push split[split.length-1]
      newArray = newArray.filter((item) -> item isnt '')
      #console.dir newArray
  )
  return newArray

exports.diff = (inputFileName, dataType) ->

  #util.timelog inputFileName, 'diff'

  #pair = ['/home/matan/ingi/repos/back-end-js/tmp/1.out', '/home/matan/ingi/repos/back-end-js/tmp/2.out']
  #pair = ['/home/matan/ingi/repos/back-end-js/tmp/2.out', '/home/matan/ingi/repos/back-end-js/tmp/1.out']
  pair = getPair(inputFileName, dataType)
  if pair?

    logging.logYellow """comparing #{pair.join(', ')}"""

    filesContent = pair.map((file) -> 
      fs.readFileSync(file, {encoding: 'utf8'}))

    contentArrays = filesContent.map((content) -> rsplit([content], ' '))

    beefedArrays = contentArrays.map((contentArray) -> rsplit(contentArray, '\n'))

    # get differences
    differ = new dtldiff.Diff(beefedArrays[0], beefedArrays[1])
    differ.compose()

    marks = 
      'add'    : '+',
      'del'    : '-',
      'common' : 'C'

    logging.logYellow """edit distance is #{differ.editdistance()}"""

    rawDiff = differ.ses(marks)

    diff = []

    sequence =
      type : null

    for diffentry in rawDiff
      type = (Object.keys diffentry)[0]
      val  = diffentry[type]

      # if we are inside a "sequence"
      if type is sequence.type
        sequence.vals.push val
      # if sequence finished, flush it and start new one
      else
        if sequence.type isnt null 
          diff.push sequence
        sequence = 
          type : type,
          vals : [val]

    diff.push sequence # flush last sequence

    result = """Shortest edit path \nfrom: #{pair[0]}\nto:   #{pair[1]}\n\n"""

    diff.filter((d) -> d.type isnt 'C') # skip sequences of no diff
        .forEach((d) -> result += d.type + d.vals.join('') + '\n')

    #console.log result

    dataWriter.write(inputFileName, """diff-#{dataType}""", result)
    dataWriter.close(inputFileName)

    #util.timelog inputFileName, 'diff'
    logging.logYellow """done comparing #{pair.join(', ')}""" 

