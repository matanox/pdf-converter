util    = require './util'
logging = require './logging' 
fs = require 'fs'
#require "jsdom"
#textHookPoint = getElementByID(window.hookPoint)
#textHookPoint.innerHTML = "aaaaa" 

# Load the output template only once
outputTemplate = fs.readFileSync('outputTemplate/template.html').toString() # this should be speedy and cached, sync won't hurt much
# Locate to the text position (inside the designated html element), 
# where the output should be inserted in the template. 
# (that's one character after the '>' closing the marked element's opening tag)
hookId = 'hookPoint'
hookElementTextPos = outputTemplate.indexOf(">", outputTemplate.indexOf('id="' + hookId + '"')) + 1

# Serves the output after inserting the transformed content
# into the designated insertion position in the template
exports.serveOutput = (html, name, res, docLogger) ->
  #logging.log(html)
 
  outputFile = '../local-copies/' + 'output/' + name + '.html'

  #Old paradigm
  #outputHtml = outputTemplate.slice(0, hookElementTextPos).concat(html, outputTemplate.slice(hookElementTextPos))
  #

  util.timelog('Saving serialized output to file')  

  fs.writeFile(outputFile, outputHtml, (err) -> 
  	
    if err?
      res.send(500)
      throw err

    util.timelog('Saving serialized output to file', docLogger)  
    #logging.log('Output saved')

    docLogger.info('Sending response....')
    util.timelog 'from upload to serving', docLogger
    res.sendfile(name + '.html', {root: '../local-copies/' + 'output/'})) # variable use by closure here...

