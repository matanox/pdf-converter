#
# Serve non-final artifacts - an original pdf, or the html conversion of it. Mainly for debugs purposes.
#

util    = require '../src/util'
storage = require '../src/storage'
logging = require '../src/logging' 
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
    
    if type?
      console.log name + ' ' + type
      switch type 
        when 'pdf'
          bytes = storage.fetch('pdf', name, serve)
        when 'html'
          res.sendfile(name + '.html', {root: '../local-copies/' + '/html-converted' + '/' + name}) # variable use by closure here...
          # as long as the intermediary html version is kept on local storage, this should work.
          # Otherwise, need to consider pushing the html *folder* from pdf2HTML into
          # the clustered file system in the first place, and manage it there

          # console.error 'this feature is not yet implemented'
          # res.send(501)
        else
          console.error 'unsupported type parameter supplied'
          res.send(500)
    else 
      console.error 'type parameter omitted'
      res.send(500)

  else
    console.error 'session does not contain the name parameter'
    res.send(500)

