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

  docDataDir = docsDataDir + '/' + inputFileName + '/'

  relevantSESs = fs.readdirSync(docDataDir).filter((SESName) -> SESName.indexOf(dataType) is 0)

  if relevantSESs.length > 1
    relevantSESs.sort().reverse() 
    return relevantSESs.slice(0, 2).map((SESName) -> docDataDir + SESName) # slice first two items, create full path

  return undefined

#
# tokenize string by a given delimiter (while preserving all occurences of the 
# delimiter as delimiting *tokens* in the output).
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

exports.diff = (context, dataType) ->
  inputFileName = context.name

  #util.timelog inputFileName, 'diff'

  #pair = ['/home/matan/ingi/repos/back-end-js/tmp/1.out', '/home/matan/ingi/repos/back-end-js/tmp/2.out']
  #pair = ['/home/matan/ingi/repos/back-end-js/tmp/2.out', '/home/matan/ingi/repos/back-end-js/tmp/1.out']
  pair = getPair(inputFileName, dataType)

  unless pair?
    logging.logYellow """skipping diff for #{inputFileName}, #{dataType}, as could not figure or find document pair to diff"""
  else
    #logging.logYellow """comparing #{pair.map(util.terminalClickableFileLink).join(' to ')}...""" 

    filesContent = pair.map((file) -> 
      fs.readFileSync(file, {encoding: 'utf8'}))

    # set output prefix 
    result = """Shortest edit path \nfrom: #{pair[0]}\nto:   #{pair[1]}\n\n"""

    # skip detailed comparison if files content is equal
    if filesContent[0] is filesContent[1] 
      editDistance = 0
    else

      contentArrays = filesContent.map((content) -> rsplit([content], ' '))

      beefedArrays = contentArrays.map((contentArray) -> rsplit(contentArray, '\n'))

      # get differences
      differ = new dtldiff.Diff(beefedArrays[0], beefedArrays[1])
      differ.compose()

      marks = 
        'add'    : '+',
        'del'    : '-',
        'common' : 'C'

      editDistance = differ.editdistance()

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

      diff.filter((d) -> d.type isnt 'C') # skip sequences of no diff
          .forEach((d) -> result += d.type + d.vals.join('') + '\n')

    #console.log result

    SES = dataWriter.getReadyName(context, """diff-#{dataType}""")
    fs.writeFile(SES, result)

    # for now, recover the run IDs from the file paths
    runIDs = pair.map((filepath) -> filepath.replace(docsDataDir + '/' + inputFileName + '/' + dataType + '*', ''))

    dataWriter.write context, 'diffs', {
        docName:      context.name
        dataType:     dataType
        run1ID:       runIDs[0]
        run2ID:       runIDs[1]
        run1link:     util.terminalClickableFileLink(pair[0])
        run2link:     util.terminalClickableFileLink(pair[1])
        editDistance: editDistance
        SESlink:      util.terminalClickableFileLink(SES)
      }

    #util.timelog inputFileName, 'diff'
    console.log """\nComparing the following #{logging.italics(dataType)} output pair found #{logging.italics('edit distance of ' + editDistance)}"""
    console.log """#{pair.map(util.terminalClickableFileLink).join('\n')}"""
    console.log """details at: #{util.terminalClickableFileLink(SES)}"""

