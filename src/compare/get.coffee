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
# pad input string with an extra new line, between each of its lines - not in use
#
pad = (string) ->
  trimmed = util.trim(string, '\n') # discard last \n
  return string.split('\n').join('\n\n') # add newline after each newline
  
iterator = (items, func) ->
  
  i = 0
  while i < items.length - 1
    curr = items[i]
    next = items[i+1]
    i += func(curr, next) 

diffFormat = (diffDescriptor) ->
  if diffDescriptor.added
    return '+ ' + diffDescriptor.value
  if diffDescriptor.removed
    return '- ' + diffDescriptor.value

intraLineFormat = (diffDescriptor) ->
  # if diff says same  
  if (not diffDescriptor.added) and (not diffDescriptor.removed) 
    return diffDescriptor.value
  # if diff says added
  if (diffDescriptor.added)
    return '<+>' + diffDescriptor.value + '</+>'

  # if diff says removed
  if (diffDescriptor.removed)
    return '<->' + diffDescriptor.value + '</->'

#
# Workaround function for making word diff treat line breaks ('\n') and extra spaces as differences rather than skip them as word delimiters
#
wrappedWordsDiff = (string1, string2) ->

  # replacement strings to use
  spaceReplacer   = 'R!!space!!R' # highly unlikely string to use as placehoder
  newlineReplacer = 'R!!newline!!R'  # highly unlikely string to use as placehoder

  # array of objects for reverting the replacement strings
  replacements  = 
  [
    orig : ' ',                
    to   : spaceReplacer
   , 
    orig : '\n', 
    to   : newlineReplacer
  ]

  replaceDoubleSpaces = (str) ->
    if str.indexOf('  ') > -1
      return replaceDoubleSpaces(str.replace('  ', ' ' + spaceReplacer))
    else 
      return str

  replace = (string) ->
    returnStr = replaceDoubleSpaces(string)
    returnStr.replace('\n', newlineReplacer, 'g')

  # beef up original strings with replacement strings, to workaround the diff shortcomings
  string1r = replace(string1)
  string2r = replace(string2)

  # diff
  wordsDiff = jsdiff.diffWords(string1r, string2r)

  # revert the replacement strings after the diff
  wordsDiff.forEach((diffDescriptor) ->
    replacements.forEach((replacer) ->
      reverted = diffDescriptor.value.replace(replacer.to, replacer.orig, 'g')
      diffDescriptor.value = reverted
    )
  )

  return wordsDiff
  

exports.diff = (inputFileName, dataType) ->

  logging.logYellow 'before diff'

  #pair = getPair(inputFileName, dataType)
  pair = ['/home/matan/ingi/repos/back-end-js/tmp/1.out', '/home/matan/ingi/repos/back-end-js/tmp/2.out']
  #pair = ['/home/matan/ingi/repos/back-end-js/tmp/2.out', '/home/matan/ingi/repos/back-end-js/tmp/1.out']
  if pair?
    filesContent = pair.map((file) -> 
      fs.readFileSync(file, {encoding: 'utf8'}))

    # get differences
    linesDiff = jsdiff.diffLines(filesContent[0], filesContent[1]).filter((diffDescriptor) -> 
        diffDescriptor.added or diffDescriptor.removed) 

    #console.dir linesDiff

    finalDiff = []

    iterator(linesDiff, (curr, next) ->
      # if consecutive pair of removed and added line diff descriptors (chunks) ->
      # then create special formatted diff output for them, as they may be similar!  
      if (curr.added and next.removed) or (curr.removed and next.added)
        # build output by word diff
        logging.cond '==== raw ===', 'diff'
        logging.cond curr, 'diff'
        logging.cond '------------', 'diff'
        logging.cond next, 'diff'

        wordsDiff = wrappedWordsDiff(curr.value, next.value)

        console.dir wordsDiff

        logging.cond '==== diff ===', 'diff'
        logging.cond wordsDiff, 'diff'
        chunk = '*'

        # map by word diff descriptor
        formatedWordSequence = wordsDiff.map((diffDescriptor) -> 
          chunk += intraLineFormat(diffDescriptor))

        logging.cond '==== chunk ===', 'diff'
        logging.cond chunk, 'diff'

        # output the word oriented diff
        finalDiff.push chunk
        return 2 # skip over current and next

      else
        # output "ordinay" linee diff
        finalDiff.push diffFormat(curr)
        return 1 # skip over current
    )

    console.log finalDiff.join('\n')
    logging.logYellow 'after diff'

