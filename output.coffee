#
# Serve the output html template for the UI of this back-end centric project
#

util    = require './util'
logging = require './logging' 
fs = require 'fs'
#require "jsdom"

#
# Load the output template only once
#
outputTemplate = fs.readFileSync('outputTemplate/template.html').toString() # this should be speedy and cached, sync won't hurt much

# Serves the output after inserting the transformed content
# into the designated insertion position in the template

exports.serveViewerTemplate = (res, docLogger) ->
  docLogger.info('Sending response....')
  util.timelog 'from upload to serving', docLogger
  res.sendfile('template.html', {root: 'outputTemplate/'}) 
  
exports.serveOutput = (name, res, docLogger) ->
  #logging.log(html)

  util.timelog('Saving serialized output to file')  
 
  outputFile = '../local-copies/' + 'output/' + name + '.html'

  outputHtml = outputTemplate
  fs.writeFile(outputFile, outputHtml, (err) -> 
  	
    if err?
      res.send(500)
      throw err

    util.timelog('Saving serialized output to file', docLogger)  
    #logging.log('Output saved')

    docLogger.info('Sending response....')
    util.timelog 'from upload to serving', docLogger
    res.sendfile(name + '.html', {root: '../local-copies/' + 'output/'})) # variable use by closure here...

