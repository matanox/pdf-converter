util = require './util'

#
# Get data that can apply to any document
#
markers = {}
exports.load = () -> 
  util.timelog('Loading markers')            
  csvToJsonConverter = require('csvtojson').core.Converter
  csvConverter = new csvToJsonConverter()
  csvConverter.on("end_parsed",(jsonFromCss) ->
    #console.log(jsonFromCss)
    markers = jsonFromCss) 

  csvFile = './markers.csv'
  csvConverter.from(csvFile)
  util.timelog('Loading markers')            
