util    = require '../util'
storage = require '../storage'
logging = require '../logging' 
fs = require 'fs'

exports.go = (req, res) -> 

  #
  # Optional TODO: Embed the pdf inside a page that still looks like you're 
  #                within the application. As much as Chrome, firefox, Safari allow.
  #                The related base code is now commented out below. Possibly
  #                the embed html tag may work if research so indicates.
  #
  serve = (bytes) ->
    console.log bytes
    if bytes
        
      # Load the output template only once
      #outputTemplate = fs.readFileSync('outputTemplate/template.html').toString() # this should be speedy and cached, sync won't hurt much
      #outputTemplate = """<html><body><div id="hookPoint"></div></body></html>"""
      #hookId = 'hookPoint'
      #hookElementTextPos = outputTemplate.indexOf(">", outputTemplate.indexOf('id="' + hookId + '"')) + 1

      # Serves the output after inserting the transformed content
      # into the designated insertion position in the template

      #outputFile = '../local-copies/' + 'pdf-serving/' + name + '.html'
      #outputHtml = outputTemplate.slice(0, hookElementTextPos).concat('', outputTemplate.slice(hookElementTextPos))
       
      #util.timelog('Saving pdf to local file')  

      ###
      fs.writeFile(outputFile, outputHtml, (err) -> 
        
        if err?
          res.send(500)
          throw err)
      ###

      #util.timelog('Saving pdf to local file')  

      console.info('Sending response....')
      util.timelog 'serving intermediary file'
      res.setHeader('Content-Type', 'application/pdf')
      res.end(bytes)
      #res.sendfile(name + '.html', {root: '../local-copies/' + 'pdf-serving/'}) # variable use by closure here...
      util.timelog 'serving intermediary file'


  if req.session.name?
    name = req.session.name
    type = req.param('type')
    console.log name + ' ' + type
    switch type 
      when 'pdf'
        bytes = storage.fetch('pdf', name, serve)
      when 'html'
        #console.error 'this feature is not yet implemented'
        res.sendfile(name + '.html', {root: '../local-copies/' + '/html-converted' + '/' + name}) # variable use by closure here...
        # to fully implement this, need to push the html file/folder from pdf2HTML into
        # the clustered file system, or serve it only from the local copies directory
        # res.send(501)
      else
        console.error 'unsupported type parameter supplied'
        res.send(500)
  else
    console.error 'session does not contain the name parameter'
    res.send(500)

