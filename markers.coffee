util = require './util'
verbex = require 'verbal-expressions'

exports.anything = verbex()
                   .then('...')
                   .maybe('.')
                   .maybe('.')
                   .anything()

#
# Get data that can apply to any document
#
markers = {}
markers.array = []
baseSieve = []
exports.baseSieve = baseSieve
#exports.markers = markers

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

  util.logObject(sieve)
  sieve


#
# Initialize a base sieve off the loaded markers.
# It will be cloned  or augmented per document.
#
createBaseSieve = (callback) ->

  add = (string, addition) -> string + addition
  tokenizeMarker = (marker) -> []

  markerId = 0
  util.timelog('Markers visualization') 
  for marker in markers.array

    seiveRow = {}
    seiveRow.markerTokens = tokenizeMarker(marker)
    seiveRow.markerId = markerId

    baseSieve.push(seiveRow)   
    markerId += 1 
  util.timelog('Markers visualization') 
  util.logObject(baseSieve)
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
