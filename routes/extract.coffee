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
# Can be rewriteen with a filter statement -- http://arcturo.github.io/library/coffeescript/04_idioms.html
filterImages = (ourDivRepresentation) ->
  filtered = []
  filtered.push(div) for div in ourDivRepresentation when not isImage(div.text)
  filtered

filterZeroLengthText = (ourDivRepresentation) ->
  filtered = []
  filtered.push(div) for div in ourDivRepresentation when not (div.text.length == 0)
  filtered

#
# Extract text content and styles from html
#
exports.go = (req, res) ->
  timer.start('Extraction from html stage A')

  # Read the input html 
  path = '../local-copies/' + 'html-converted/' 
  name = req.query.name
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString()

  # Extract all style info 
  realStyles = css.simpleFetchStyles(rawHtml ,path + name + '/') 

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

  # Discard any divs that contain zero-length text
  divsAndStyles = filterZeroLengthText(divsAndStyles)

  # Now tokenize (from text into words, punctuation, etc.)
  tokenizedDivs = (html.tokenize(div) for div in divsAndStyles)

  tokens = []
  for div in tokenizedDivs
  	for token in div
  	  tokens.push(token)

  # TODO: duplicate to unit test
  for token in tokens
    if token.text.length == 0
      throw "Error - zero length text in data"

  #console.dir(tokens)

  if tokens.length == 0
  	console.log("No text was extracted from input")
  	throw("No text was extracted from input")
  
  ###
  collapsedTokens = []
  tokens.reduce (x, y) ->
  	if util.endsWith(x.text, '-')
  	  collapsedTokens.push(html.mergeTokens(x, y))
  	else
  	  collapsedTokens.push(x)
  	return y
  ###
  
  #console.log(token.text) for token in tokens
  plainText = tokens.map (x) -> x.text
  plainText = plainText.reduce (x, y) -> x + ' ' + y
  # console.log(plainText)
  #	x.concat()

  timer.end('Extraction from html stage A')

  timer.start('Extraction from html stage B')
  outputHtml = soup.build(plainText)
  timer.end('Extraction from html stage B')

  output.serveOutput(outputHtml, name, res)

  # res.sendfile('../local-copies/' + 'output/' + name + ".html")
  # res.send("read raw html of length " + rawHtml.length + " bytes")
  