util = require('./util')
css  = require('./css')

#
# Filter the raw html for only divs that do not contain an inner div
# that's because we don't care about wrapper divs that don't contain text content,
# at least with html2pdfEX as the original source.
#
exports.removeOuterDivs = (string) ->
  regex = new RegExp('<div((?!div).)*</div>', 'g') # g indicates to yield all, not just first match
  return string.match(regex) 

parseCssClassesOld = (xmlNode) ->
  # Build an array of the classes included by the div's "class=" statement.
  # Admittedly this is quite pdf2htmlEX specific parsing....
  
  regex = new RegExp("<div class=\".*?\"", 'g') # Regex match: Extract up to the end of
  cssClassesString = xmlNode.match(regex)		# 			   the classes string of a div 	
  cssClassesString = util.strip(cssClassesString[0], "<div class=\"", "\"") # Now strip the string
  
  # Regex match: Extract the class names
  regex = new RegExp("\\b\\S+?\\b", 'g') # first slash is for the string, not the regex
  cssClasses = cssClassesString.match(regex)
  cssClasses

# Takes a raw node, and creates a representation holding
# its content and style such that it can be worked with
exports.representNodeOld = (xmlNode) ->
  # assumes there are no nested divs inside xmlNode
  text = util.parseElementTextOld(xmlNode)
  styles = parseCssClassesOld(xmlNode)
  #console.log("empty object") unless text
  return {text, styles}

#
# Serializes html hierarchy into a sequence of 
# tokens composed of text and style each.
#
# Basically it recursively walks the object model having been composed
# by htmlparser2 from raw html, and spits out one token for each piece of text. 
#
# The htmlparser2 object model can be seen and explored here - 
# http://demos.forbeslindesay.co.uk/htmlparser2/
#
exports.representNodes = (domObject) ->

  myObjects = []

  handleNode = (domObject, styles) ->
    for object in domObject
      switch object.type 
        when 'tag'

          if object.children?
            handleNode(object.children, object.attribs['class'])            
            
        when 'text' 
          # flush a new object
          text = object.data
          myObjects.push({styles: styles, text: text})

  handleNode(domObject)

  console.log myObjects
  return myObjects

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

punctuation = [',',
               ':',
               ';',
               '.',
                ')']

# Tokenize strings to words and punctuation,
# while also conserving the association to the style attached to the input.
exports.tokenize = (string) ->

  # Splits punctuation that is the last character of a token
  # E.g. ['aaa', 'bbb:', 'ccc'] => ['aaa', 'bbb', ';', 'ccc']
  splitBySuffixChar = (inputTokens) ->

    punctuation = [',',
                   ':',
                   ';',
                   '.',
                   ')']

    tokens = []
    for token in inputTokens 
      switch token.metaType

        when 'delimiter' then tokens.push(token)

        when 'regular' 
          text = token.text
          endsWithPunctuation = util.endsWithAnyOf(text, punctuation)
          if endsWithPunctuation and (text.length > 1)
            # Split it into two
            tokens.push( {'metaType': 'regular', 'text': text.slice(0, text.length - 1)} ) # all but last char
            tokens.push( {'metaType': 'regular', 'text': text.slice(text.length - 1)} )    # only last char	      
          else 
            # Push as is
            tokens.push(token)	

        else 
          throw 'Invalid token meta-type encountered'
          util.logObject(token)

    tokens

  # Splits punctuation that is the first character of a token
	# E.g. ['aaa', '(bbb', 'ccc'] => ['aaa', '(', bbb', 'ccc']
  splitByPrefixChar = (inputTokens) ->

    punctuation = ['(']
	  
    tokens = []

    for token in inputTokens 

      switch token.metaType

        when 'delimiter' then tokens.push(token)

        when 'regular' 
          text = token.text
          startsWithPunctuation = util.startsWithAnyOf(text, punctuation)
          if startsWithPunctuation and (text.length > 1)
            # Split it into two
            tokens.push( {'metaType': 'regular', 'text': text.slice(0, 1)} ) # only first char
            tokens.push( {'metaType': 'regular', 'text': text.slice(1)} )    # all but first char
          else 
            # Push as is
            tokens.push(token) 
        
        else 
          throw "Invalid token meta-type encountered"
          util.logObject(token)

    tokens
  
  # This can be shortened to a one-liner a la 
  # http://coffeescriptcookbook.com/chapters/arrays/filtering-arrays
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
  
  # Split into tokens
  tokenize = (string) ->

    insideWord      = false
    insideDelimiter = false
    tokens = []

    if string.length == 0 then return []

    for i in [0..string.length-1] 
      # console.log i
      char = string.charAt(i)
      if util.isAnySpaceChar(char) 
        # Push a delimiter token if encountered,
        # while supressing multiple consequtive spaces into a single delimiter token
        
        # Push the last accumulated word if any
        if insideWord
          tokens.push( {'metaType': 'regular', 'text': word} )
          insideWord = false

        unless insideDelimiter
          tokens.push( {'metaType': 'delimiter'} )
          insideDelimiter = true

      else 
        if insideDelimiter then insideDelimiter = false
        if insideWord 
          word = word.concat(char)
        else 
          word = char
          insideWord = true

    tokens.push( {'metaType': 'regular', 'text': word} ) if insideWord # flushes the last word if any

    #console.log(tokens)

    tokens

  tokens = tokenize(string)

  #spaceDelimitedTokens = string.text.split(/\s/) # split by any space character
  #spaceDelimitedTokens = filterEmptyString(spaceDelimitedTokens)

  # Split more to tokenize select punctuation marks as tokens
  tokens = splitBySuffixChar(tokens)
  tokens = splitByPrefixChar(tokens)
  #console.dir(tokens)  

  # TODO: duplicate this into unit test for prior functions
  for token in tokens when token.metaType == 'regular'
    if token.text.length == 0
      throw "error in tokenize"
  
  #console.dir(tokens)  
  tokens

#
# Build html output -
# This old version builds the output based only on the original styles of each token
# Not the computed styles later attached to it, or more advanced features.
#
exports.buildOutputHtmlOld = (tokens, finalStyles) ->

  #
  # Building the output for a single token....
  #
  wrapWithAttributes = (token, moreStyle) ->

    stylesString = ''
    for style in token.styles
      styles = css.getFinalStyles(style, finalStyles)
      if styles?
        serialized = css.serializeStylesArray(styles)
        stylesString = stylesString + serialized

    if moreStyle? then stylesString = stylesString + ' ' + moreStyle

    if stylesString.length > 0
      stylesString = 'style=\"' + stylesString + '\"'
      if token.metaType is 'regular' 
        text = token.text
      else 
        text = ' '
      return """<span #{stylesString} id="#{x.id}">#{text}</span>\n"""
    else 
      console.warn('token had no styles attached to it when building output')
      return "<span>#{token.text}</span>"


  util.timelog('Serialization to output')  

  for x in tokens 
    if x.metaType is 'regular'
      plainText = plainText + wrapWithAttributes(x)
    else 
      plainText = plainText + wrapWithAttributes(x, 'white-space:pre;')

  util.timelog('Serialization to output') 

  #console.log(plainText)
  plainText


#
# Build html output
#
exports.buildOutputHtml = (tokens, finalStyles) ->

  #
  # Building the output for a single token....
  #
  wrapWithAttributes = (token, moreStyle) ->

    stylesString = ''
    for style, val of token.finalStyles
      stylesString = stylesString + style + ':' + val + '; '

    if moreStyle? then stylesString = stylesString + ' ' + moreStyle

    if stylesString.length > 0
      stylesString = 'style=\"' + stylesString + '\"'
      if token.metaType is 'regular' 
        text = token.text
      else 
        text = ' '
      return """<span #{stylesString} id="#{x.id}">#{text}</span>\n"""
    else 
      console.warn('token had no styles attached to it when building output')
      return "<span>#{token.text}</span>"


  util.timelog('Serialization to output')  

  for x in tokens 
    if x.metaType is 'regular'
      plainText = plainText + wrapWithAttributes(x)
    else 
      plainText = plainText + wrapWithAttributes(x, 'white-space:pre;') # makes white-space chars show...

  util.timelog('Serialization to output') 

  #console.log(plainText)
  plainText
