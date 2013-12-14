util = require('./util')

#
# Filter the raw html for only divs that do not contain an inner div
# that's because we don't care about wrapper divs that don't contain text content,
# at least with html2pdfEX as the original source.
#
exports.removeOuterDivs = (string) ->
  regex = new RegExp('<div((?!div).)*</div>', 'g') # g indicates to yield all, not just first match
  return string.match(regex) 

parseCssClasses = (xmlNode) ->
  # Build an array of the classes included by the div's "class=" statement.
  # Admittedly this is quite pdf2htmlEX specific parsing....
  
  regex = new RegExp("<div class=\".*?\"", 'g') # Regex match: Extract up to the end of
  cssClassesString = xmlNode.match(regex)		# 			   the classes string of a div 	
  cssClassesString = util.strip(cssClassesString[0], "<div class=\"", "\"") # Now strip the string
  
  # Regex match: Extract the class names
  regex = new RegExp("\\b\\S+?\\b", 'g') # first slash is for the string, not the regex
  cssClasses = cssClassesString.match(regex)
  cssClasses

# Takes a raw Div, and creates a representation holding
# its content and style such that it can be worked with
exports.representDiv = (xmlNode) ->
  # assumes there are no nested divs inside xmlNode
  text = util.parseElementText(xmlNode)
  styles = parseCssClasses(xmlNode)
  #console.log("empty object") unless text
  return {text, styles}

#
# Collapses a div into its cummulative text content by stripping
# each span's header and trailer tags. This is somewhat pdf2htlmEX
# specific in assuming divs only contain spans (if at all), and only 
# contain spans that don't specify styles we need to bother with.
#
# This is ugly as this function accepts the whole div and not just
# its text, but otherwise the function couldn't change the div's text 
# given Javascript's argument passing realities - 
# http://stackoverflow.com/questions/6605640/javascript-by-reference-vs-by-value
#
exports.stripSpanWrappers = (div) ->
  spanBegin = new RegExp('<span.*?>', 'g')
  spanEnd 	= new RegExp('</span>', 'g')
  div.text = div.text.replace(spanBegin, '') 
  div.text = div.text.replace(spanEnd, '')
 
exports.mergeTokens = (x, y) ->
  console.log("Merging")

  merged = util.clone(x)
  merged.text = x.text + y.text

  console.dir(x)
  console.dir(y)  
  console.dir(merged)

  console.log("end merge")

  merged

# Tokenize strings to words and punctuation,
# while also conserving the association to the style attached to the input.
exports.tokenize = (styledText) ->

  # Splits punctuation that is the last character of a token
  # E.g. ['aaa', 'bbb:', 'ccc'] => ['aaa', 'bbb', ';', 'ccc']
	splitBySuffixChar = (spaceDelimitedTokens) ->

	  punctuation = [',',
	                 ':',
	                 ';',
	                 '.',
	                 ')']

	  tokens = []
	  for token in spaceDelimitedTokens 
	    endsWithPunctuation = util.endsWithAnyOf(token, punctuation)
	    if endsWithPunctuation and token.length > 1
        tokens.push(token.slice(0, token.length - 1)) # all but last char
        tokens.push(token.slice(token.length - 1))    # only last char	      
	    else 
        tokens.push(token)	      

	  tokens

  # Splits punctuation that is the first character of a token
	# E.g. ['aaa', '(bbb', 'ccc'] => ['aaa', '(', bbb', 'ccc']
	splitByPrefixChar = (spaceDelimitedTokens) ->

	  punctuation = ['(']
	  
	  tokens = []
	  for token in spaceDelimitedTokens 
	    startsWithPunctuation = util.startsWithAnyOf(token, punctuation)
	    if startsWithPunctuation and token.length > 1
        tokens.push(token.slice(0, 1)) # only first char
        tokens.push(token.slice(1))    # all but first char
	    else 
        tokens.push(token)
	  
	  tokens
  
  filterEmptyString = (tokens) ->
    filtered = []
    filtered.push(token) for token in tokens when token.length > 0
    filtered

  # First off, tokenizing by space characters
  #
  # In the process, double spaces (or more generally, sequences of spaces),  
  # are automatically suppressed here for now. That's good as:
  # at least pdf2htmlEX may provide double spaces where the 
  # original line of text is very sparse (typically due to 
  # accomodating all lines ending at the same pixel location).

  # Record whether the string ends with a space character or not.
  # This indicates whether the last token to be detected on it
  # is itself post-delimited by a space or not - which matters.
  if util.anySpaceChar.test(styledText.text.slice(-1)) 
    postDelimited = true
  else
    postDelimited = false
  
  # Split into tokens
  spaceDelimitedTokens = styledText.text.split(/\s/) # split by any space character
  spaceDelimitedTokens = filterEmptyString(spaceDelimitedTokens)

  # Split more to tokenize select punctuation marks as tokens
  tokens = splitBySuffixChar(spaceDelimitedTokens)
  tokens = splitByPrefixChar(tokens)

  # TODO: duplicate this into unit test for prior functions
  for token in tokens
    if token.length == 0
      throw "error in tokenize"
  
  # Now, build token objects comprising the text tokens AND their style, 
  # assigning the style of the div to each of them.
  tokensWithStyle = ({'text': token, 'postDelimited': true, 'styles': styledText.styles} for token in tokens)
  #console.log tokensWithStyle.length
  #console.dir styledText
  #tokensWithStyle[tokensWithStyle.length-1].postDelimited = postDelimited # Mark last token's state
  tokensWithStyle
