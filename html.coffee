util = require('./util')
css  = require('./css')

parseCssClasses = (styleString) ->
  # Build an array of the classes included by the div's "class=" statement.
  # Admittedly this is quite pdf2htmlEX specific parsing....
  
  # Regex match: Extract the class names
  regex = new RegExp("\\b\\S+?\\b", 'g') # first slash is for the string, not the regex
  cssClasses = styleString.match(regex)
  cssClasses

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

  handleNode = (domObject, stylesArray) ->
    for object in domObject
      switch object.type 
        when 'tag' 
          # recurse for all children
          if object.children?

            if not stylesArray? then stylesArray = []           # initialize when styles parameter is not supplied
            
            inheritingStylesArray = (styles for styles in stylesArray)

            styleString = object.attribs['class']               # the styles string (style="...) of the html node
            if styleString?
              styles = parseCssClasses(styleString.toString())  # an array of the class names parsed from it
                                                                #
                                                                #    this two-dim array mimics the node hierarchy
                                                                #    every item on it is an array from the current
                                                                #    or a parent html node
            
              inheritingStylesArray.push(styles) 
              #console.log inheritingStylesArray

            handleNode(object.children, inheritingStylesArray)    # recurse with the style of this object
            
        when 'text' 
          unless object.data is '\n'   # ingore bare newlines in between html elements
            # flush a new object
            text = object.data
            myObjects.push({text, stylesArray})
            #console.log 'adding text'
            #console.log text 
            #console.log stylesArray

  handleNode(domObject)

  #util.logObject myObjects
  return myObjects

punctuation = [',',
               ':',
               ';',
               '.',
                ')']

# Tokenize strings to words and punctuation,
# while also conserving the association to the style attached to the input.
exports.tokenize = (nodeWithStyles) ->

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
            unless (util.lastChar(text) is ';' and /.?&.*\b;$/.test(text)) # avoid splitting something like &amp; into &amp and ;
                                                                           # Regex description: 
                                                                           #    any string, including the & character
                                                                           #    where & is followed by word chars,
                                                                           #    and then a first non-word delimiter which is ;
                                                                           #    which is the last character of the string              
              # Split it into two
              tokens.push( {'metaType': 'regular', 'text': text.slice(0, text.length - 1), 'stylesArray': token.stylesArray} ) # all but last char
              tokens.push( {'metaType': 'regular', 'text': text.slice(text.length - 1), 'stylesArray': token.stylesArray} )    # only last char	      
            else
               # Push as is
               tokens.push(token)  
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
            tokens.push( {'metaType': 'regular', 'text': text.slice(0, 1), 'stylesArray': token.stylesArray} ) # only first char
            tokens.push( {'metaType': 'regular', 'text': text.slice(1), 'stylesArray': token.stylesArray} )    # all but first char
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

  tokenize = (nodeWithStyles) ->

    # Function for passing on style to each token being created.
    # The style of each token being created is that of the node 
    # from which it is being parsed herein. 
    withStyles = (token) -> 
      token.stylesArray = nodeWithStyles.stylesArray
      token

    string = nodeWithStyles.text

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
          tokens.push( withStyles {'metaType': 'regular', 'text': word} )
          insideWord = false

        unless insideDelimiter
          tokens.push( withStyles {'metaType': 'delimiter'} )
          insideDelimiter = true

      else 
        if insideDelimiter then insideDelimiter = false
        if insideWord 
          word = word.concat(char)
        else 
          word = char
          insideWord = true

    tokens.push( withStyles {'metaType': 'regular', 'text': word} ) if insideWord # flushes the last word if any

    #console.log(tokens)

    tokens

  tokens = tokenize(nodeWithStyles)

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
      #return """<span #{stylesString} id="#{x.id}">#{text}</span>\n"""
      return """<span #{stylesString} id="#{x.id}">#{text}</span>"""
    else 
      console.warn('token had no styles attached to it when building output. token text: ' + token.text)
      return "<span>#{token.text}</span>"


  util.timelog('Serialization to output')  

  for x in tokens 
    if x.metaType is 'regular'
      plainText = plainText + wrapWithAttributes(x)
    else 
      #plainText = plainText + wrapWithAttributes(x, 'white-space:pre;') # makes white-space chars show...
      plainText = plainText + wrapWithAttributes(x)

  util.timelog('Serialization to output') 

  #console.log(plainText)
  plainText
