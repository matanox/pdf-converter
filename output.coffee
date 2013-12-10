require "fs"
require "jsdom"

#textHookPoint = getElementByID(window.hookPoint)
#textHookPoint.innerHTML = "aaaaa" 

exports.serveOutput = (text, name, res) ->
  outputFile = './local-copies/' + 'output/' + name + '.html'
  
  fs.writeFile(outputFile, "aaa", (err) -> 
  	
  	if err?
  	  res.send(500)
  	  throw err

  	console.log('Output saved')
  	console.log('Sending response....')
  	res.sendfile(outputFile) # variable use by closure here...
  	)
