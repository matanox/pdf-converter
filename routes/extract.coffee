require "fs"
util   = require "../util"
timer  = require "../timer"
css    = require "../css"
html   = require "../html"
model  = require "../model"
soup   = require "../soup"
output = require "../output"

# Utility function for filtering out images
filterImages = (ourDivRepresentation) ->
    filtered = []
    filtered.push(div) for div in ourDivRepresentation when not util.startsWith(div.text, "<img ")
    filtered

#
# Extract text content and styles from html
#
exports.go = (req, res) ->
  timer.start('Extraction from html stage A')

  path = '../local-copies/' + 'html-converted/' 
  name = req.query.name
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString()

  realStyles = css.simpleFetchStyles(rawHtml ,path + name + '/') # extract all style info

  rawRelevantDivs = html.removeOuterDivs(rawHtml)
  divsAndStyles = (html.representDiv div for div in rawRelevantDivs)

  # For now, remove any images, brute force. This code will not persist
  # And is not sufficient for also removing their text overlay
  divsAndStyles = filterImages(divsAndStyles)

  # For now, extract all text inside each div, without any discrimination 
  # for what's directly included or nested in spans - all text is concatenated.
  html.stripSpanWrappers(div) for div in divsAndStyles

  tokensAndStyles = (html.tokenizeWithStyle(div) for div in divsAndStyles)
  
  timer.end('Extraction from html stage A')

  #util.logObject(realStyles)
  #util.logObject(divsAndStyles)
  util.logObject(tokensAndStyles)

  timer.start('Extraction from html stage B')

  soup.build(divsAndStyles)
  timer.end('Extraction from html stage B')
  outputHtml = "aaa"

  output.serveOutput(outputHtml, name, res)

  # res.sendfile('../local-copies/' + 'output/' + name + ".html")

  # res.send("read raw html of length " + rawHtml.length + " bytes")
  