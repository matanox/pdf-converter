require "fs"
util   = require "../util"
timer  = require "../timer"
css    = require "../css"
html   = require "../html"
model  = require "../model"
soup   = require "../soup"
output = require "../output"

isImage = (text) -> util.startsWith(text, "<img ")

# Utility function for filtering out images
filterImages = (ourDivRepresentation) ->
  filtered = []
  filtered.push(div) for div in ourDivRepresentation when not isImage(div.text)
  filtered

filterNoText = (ourDivRepresentation) ->
  filtered = []
  filtered.push(div) for div in ourDivRepresentation when not (div.text.length == 0)
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

  # Keep divs without their wrapping div if any.
  rawRelevantDivs = html.removeOuterDivs(rawHtml)

  # Create array of objects holding the text and style of each div
  divsAndStyles = (html.representDiv div for div in rawRelevantDivs)

  # For now, remove any images, brute force. This code will not persist
  # And is not sufficient for also removing their text overlay
  divsAndStyles = filterImages(divsAndStyles)

  # For now, extract all text inside each div, indifferently to 
  # what's directly included v.s. what's nested in spans - 
  # all text is equally concatenated.
  html.stripSpanWrappers(div) for div in divsAndStyles

  # Discard any divs that contain no text at all
  divsAndStyles = filterNoText(divsAndStyles)

  # Now tokenize (from text into words, punctuation, etc.)
  tokensAndStyles = (html.tokenize(div) for div in divsAndStyles)

  timer.end('Extraction from html stage A')

  timer.start('Extraction from html stage B')
  soup.build(divsAndStyles)
  timer.end('Extraction from html stage B')

  outputHtml = "aaa"

  output.serveOutput(outputHtml, name, res)

  # res.sendfile('../local-copies/' + 'output/' + name + ".html")

  # res.send("read raw html of length " + rawHtml.length + " bytes")
  