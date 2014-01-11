util = require './util'
verbex = require 'verbal-expressions'

inputLang = {}
inputLang.oneOrMoreWords = verbex()
                           .then('..')
                           .maybe('.')
                           .maybe('.')
                           .maybe('.')

internalLang = {}
internalLang.oneOrMoreWords = '\\*'

#
# Get data that can apply to any document
#
markers = {}
markers.array = []
baseSieve = []
exports.baseSieve = baseSieve

#
# Tokenize a marker
# Note: some nuances here may be superfluous as it was ported from the text tokenization function
#       to refactor after basic functionality has been proven
#
tokenizeMarker = (marker) ->

  sanitizeMarker = (marker) ->

    if inputLang.oneOrMoreWords.test(marker.WordOrPattern)
      marker.WordOrPattern = marker.WordOrPattern.replace(inputLang.oneOrMoreWords , internalLang.oneOrMoreWords)  

  sanitizeMarker(marker)
  string = marker.WordOrPattern

  insideWord      = false
  insideDelimiter = false
  tokens = []

  if string.length == 0 then return []

  for i in [0..string.length-1] 
    # console.log i
    char = string.charAt(i)
    if util.isAnySpaceChar(char) 
      # Push a delimiter token if encountered,
      # while supressing multiple consequtive spaces into a single delimiter token
      
      # Push the last accumulated word if any
      if insideWord
        tokens.push( {'metaType': 'regular', 'text': word} )
        insideWord = false

      unless insideDelimiter
        tokens.push( {'metaType': 'delimiter'} )
        insideDelimiter = true

    else 
      if insideDelimiter then insideDelimiter = false
      if insideWord 
        word = word.concat(char)
      else 
        word = char
        insideWord = true

  tokens.push( {'metaType': 'regular', 'text': word} ) if insideWord # flushes the last word if any

  #
  # Convert special token texts to their meaning.
  # For now, only the wildcard.
  #
  for token in tokens
    if token.metaType is 'regular' and token.text is internalLang.oneOrMoreWords
      delete token.text
      token.metaType = 'anyOneOrMore'

  # Discard delimiters (for the time being)
  #console.log('before ' + tokens.length)
  tokens = tokens.filter((token) -> token.metaType isnt 'delimiter')
  #console.log('after ' + tokens.length)
  #util.logObject(tokens)

  tokens

#
# Derive a working copy sieve by deep copying the base sieve, and augment it
#
exports.createDocumentSieve = (baseSieve) ->
  sieve = []
  for baseSieveRow in baseSieve
    #
    # clone the original row
    #
    sieveRow = {}
    for k of baseSieveRow 
      sieveRow[k] = baseSieveRow[k] 

      sieve.push(sieveRow)

  #util.logObject(sieve)
  sieve


#
# Initialize a base sieve off the loaded markers.
# It will be cloned  or augmented per document.
#
createBaseSieve = (callback) ->

  add = (string, addition) -> string + addition

  markerId = 0
  util.timelog('Markers visualization') 
  for marker in markers.array

    seiveRow = {}
    seiveRow.markerTokens = tokenizeMarker(marker)
    seiveRow.markerId = markerId

    baseSieve.push(seiveRow)   
    markerId += 1 
  util.timelog('Markers visualization') 
  #rsutil.logObject(baseSieve)
  callback()

#
# Load markers
#
exports.load = (callback) -> 
  util.timelog('Loading markers')            
  csvToJsonConverter = require('csvtojson').core.Converter
  csvConverter = new csvToJsonConverter()
  csvConverter.on("end_parsed",(jsonFromCss) ->
    #console.log(jsonFromCss)
    markers.array = jsonFromCss.csvRows
    #console.log(markers)
    util.timelog('Sorting markers')            
    markers.array.sort((a, b) -> # simple sort by lexicographic order obliviously of the case of equality
      if a.WordOrPattern > b.WordOrPattern
        return 1
      else
        return -1)
    util.timelog('Sorting markers')            

    util.timelog('Loading markers')            
    (createBaseSieve(callback))
    ) 

  csvFile = './markers.csv'
  csvConverter.from(csvFile)



# Interpret markers - this can be avoided if markers are more uniformely preprocessed
#for marker in markers

# sort



#checkApplicability = (marker) ->
