require "fs"
#require "jsdom"
#textHookPoint = getElementByID(window.hookPoint)
#textHookPoint.innerHTML = "aaaaa" 

# Load the output template only once
outputTemplate = fs.readFileSync('outputTemplate/index.html').toString() # this should be speedy and cached, sync won't hurt much
# Locate to the text position (inside the designated html element), 
# where the output should be inserted in the template. 
# (that's one character after the '>' closing the marked element's opening tag)
hookId = 'hookPoint'
hookElementTextPos = outputTemplate.indexOf(">", outputTemplate.indexOf('<span id="' + hookId + '"')) + 1

# Serves the output after inserting the transformed content
# into the designated insertion position in the template
exports.serveOutput = (html, name, res) ->
  #console.log(html)
 
  outputFile = '../local-copies/' + 'output/' + name + '.html'

  outputHtml = outputTemplate.slice(0, hookElementTextPos).concat(html, outputTemplate.slice(hookElementTextPos))
 
  timer.start('Saving serialized output to file')  

  fs.writeFile(outputFile, outputHtml, (err) -> 
  	
    if err?
      res.send(500)
      throw err

    timer.end('Saving serialized output to file')  
    #console.log('Output saved')

    console.log('Sending response....')
    res.sendfile(name + '.html', {root: '../local-copies/' + 'output/'})) # variable use by closure here...
