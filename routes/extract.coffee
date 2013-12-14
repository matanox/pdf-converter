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
  divsWithStyles = (html.representDiv div for div in rawRelevantDivs)

  # For now, remove any images, brute force. This code will not persist
  # And is not sufficient for also removing their text overlay
  divsWithStyles = filterImages(divsWithStyles)

  # For now, extract all text inside each div, indifferently to 
  # what's directly included v.s. what's nested in spans - 
  # all text is equally concatenated.
  html.stripSpanWrappers(div) for div in divsWithStyles

  # Discard any divs that contain zero-length text
  divsWithStyles = filterZeroLengthText(divsWithStyles)

  # Now tokenize (from text into words, punctuation, etc.),
  # while inheriting the style of the div to each resulting token
  divTokens = []
  for div in divsWithStyles
    tokens = html.tokenize(div.text)
    for token in tokens # inherit the styles to all tokens
      switch token.metaType
        when 'regular' then token.styles = div.styles
    divTokens.push(tokens)

  #console.log(divTokens)

  # Flatten to one-dimensional array of tokens... farewell divs.
  tokens = []
  for div in divTokens
  	for token in div
  	  tokens.push(token)

  # TODO: duplicate to unit test
  for token in tokens when token.metaType == 'regular'
    if token.text.length == 0
      throw "Error - zero length text in data"

  console.dir(tokens)

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
  console.log("plaintext")
  plainText = ''
  for token in tokens
    if token.metaType is 'regular' 
      plainText = plainText.concat(token.text)
    else 
      plainText = plainText.concat(' ')

  console.log(plainText)
  #	x.concat()

  timer.end('Extraction from html stage A')

  timer.start('Extraction from html stage B')
  outputHtml = soup.build(plainText)
  timer.end('Extraction from html stage B')

  output.serveOutput(outputHtml, name, res)

  # res.sendfile('../local-copies/' + 'output/' + name + ".html")
  # res.send("read raw html of length " + rawHtml.length + " bytes")
  