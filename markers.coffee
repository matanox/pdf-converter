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
exports.markers = markers

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
    callback()
    ) 

  csvFile = './markers.csv'
  csvConverter.from(csvFile)


# Interpret markers - this can be avoided if markers are more uniformely preprocessed
#for marker in markers

# sort



#checkApplicability = (marker) ->
