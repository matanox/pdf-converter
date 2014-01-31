util    = require '../util'
storage = require '../storage'
logging = require '../logging' 
fs = require 'fs'

exports.go = (req, res) -> 

  serve = (pdfBytes) ->
    console.log pdfBytes
    if pdfBytes
        
      # Load the output template only once
      #outputTemplate = fs.readFileSync('outputTemplate/template.html').toString() # this should be speedy and cached, sync won't hurt much

      outputTemplate = """<html><body><div id="hookPoint"></div></body></html>"""

      # Locate to the text position (inside the designated html element), 
      # where the output should be inserted in the template. 
      # (that's one character after the '>' closing the marked element's opening tag)
      hookId = 'hookPoint'
      hookElementTextPos = outputTemplate.indexOf(">", outputTemplate.indexOf('id="' + hookId + '"')) + 1

      # Serves the output after inserting the transformed content
      # into the designated insertion position in the template

      outputFile = '../local-copies/' + 'pdf-serving/' + name + '.html'

      outputHtml = outputTemplate.slice(0, hookElementTextPos).concat('', outputTemplate.slice(hookElementTextPos))
       
      util.timelog('Saving pdf to local file')  

      fs.writeFile(outputFile, outputHtml, (err) -> 
        
        if err?
          res.send(500)
          throw err)

      util.timelog('Saving pdf to local file')  
      #logging.log('Output saved')

      console.info('Sending response....')
      util.timelog 'serving original pdf'
      res.setHeader('Content-Type', 'application/pdf')
      res.end(pdfBytes)
      #res.sendfile(name + '.html', {root: '../local-copies/' + 'pdf-serving/'}) # variable use by closure here...

      util.timelog 'serving original pdf'


  if req.query.name?
    name = req.query.name
    console.log name
    pdfBytes = storage.fetch('pdf', name, serve)
  else
    console.error 'request missing the name parameter'
    res.send(500)

