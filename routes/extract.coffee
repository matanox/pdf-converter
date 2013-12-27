require "fs"
util   = require "../util"
timer  = require "../timer"
css    = require "../css"
html   = require "../html"
model  = require "../model"
output = require "../output"
ctype  = require "../ctype"

isImage = (text) -> util.startsWith(text, "<img ")

# Utility function for filtering out images
# Can be rewriteen with a filter statement -- 
# http://coffeescriptcookbook.com/chapters/arrays/filtering-arrays
# http://arcturo.github.io/library/coffeescript/04_idioms.html
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
  util.timelog('Extraction from html stage A')

  # Read the input html 
  path = '../local-copies/' + 'html-converted/' 
  name = req.query.name
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString()

  # Extract all style info 
  inputStylesMap = css.simpleFetchStyles(rawHtml ,path + name + '/') 

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

  #

  # Discern whether to imply a delimiter at the end of each div, or 
  # a delimiter is *already* explicitly included at the end of each div.
  divsNum = divsWithStyles.length
  endsSpaceDelimited = 0
  
  for div in divsWithStyles
    #console.log(div.text)
    #console.log(util.lastChar(div.text))
    #console.log(util.isAnySpaceChar(util.lastChar(div.text)))
    #console.log()
    if util.isAnySpaceChar(util.lastChar(div.text)) then endsSpaceDelimited += 1
  
  # If most divs end with a delimiting space character, then we don't need
  # to implicitly infer a delimiter at the end of each div, otherwise we do.
  # The use of a constant ratio test is extremely coarse and temporary,
  # a refined solution should replace it.
  console.log(endsSpaceDelimited)
  console.log(endsSpaceDelimited / divsNum)
  if (endsSpaceDelimited / divsNum) < 0.3 then augmentEachDiv = true else augmentEachDiv = false

  # Now tokenize (from text into words, punctuation, etc.),
  # while inheriting the style of the div to each resulting token
  divTokens = []
  for div in divsWithStyles
    tokens = html.tokenize(div.text)
    for token in tokens # inherit the styles to all tokens
      switch token.metaType
        when 'regular' then token.styles = div.styles
    if augmentEachDiv then tokens.push( {'metaType': 'delimiter'} ) # add a delimiter in this case
    divTokens.push(tokens)

  # Flatten to one-dimensional array of tokens... farewell divs.
  tokens = []
  for div in divTokens
    for token in div
      tokens.push(token)

  # TODO: duplicate to unit test
  for token in tokens when token.metaType == 'regular'
    if token.text.length == 0
      throw "Error - zero length text in data"

  if tokens.length == 0
    console.log("No text was extracted from input")
    throw("No text was extracted from input")

  #
  # Unite token couples that have no delimiter in between them,
  # the first of which ending with '-' (while applying the
  # styles of the first one to both).
  #
  # E.g. 'associa-', 'ted' -> 'associated'
  # 
  # This has two effects:
  # (1) fuses words cut at the end of a line using the notorious hyphen notation
  # (2) treat any couple that is united by a hyphen as one token, which will prevent
  #     them being separated on an end of a line in final output
  #
  # Note: this should also unite triples and so on, not just couples
  #
  # Note: the use of reduce is a bit hackish, a simpler iterator function that 
  #       iterates from the second element and provides access to a 'previous' element  
  #       and a 'current' element would be a good refactoring.
  #
  tokens.reduce (x, y, index) -> 
    if x.metaType is 'regular' and y.metaType is 'regular'

      if util.endsWith(x.text, '-')
        x.text = x.text.slice(0, -1)   # discard the hyphen
        x.text = x.text.concat(y.text) # concatenate text of second element into first
        tokens.splice(index, 1)        # remove second element
        return x
    return y

  # Now repeat with variation, for the case that end-of-lines 
  # are appended with a delimiter. That case would not get caught above.
  # Can probably collapse this when the code is more mature.
  tokens.reduce (x, y, index) -> 
    if x.metaType is 'regular' and y.metaType is 'delimiter' and index < (tokens.length - 1)

      if util.endsWith(x.text, '-')
        x.text = x.text.slice(0, -1)                   # discard the hyphen
        x.text = x.text.concat(tokens[index + 1].text) # concatenate text of second element 
                                                       # (the one after the delimiter) into first
        tokens.splice(index, 2)                        # remove second element (the one after the delimiter) 
                                                       # and the delimiter
        return x
    return y
  
  util.timelog('Extraction from html stage A')

  # Add unique ids to tokens
  id = 0
  for token in tokens
    token.id = id
    id += 1

  # Smooth out styles such that each delimiter 
  # inherits the style of its preceding token. 
  # May belong either here or inside the core tokenization...
  tokens.reduce (x, y) -> 
    if y.metaType is 'delimiter' then y.styles = x.styles
    return y

  #
  # Add final styles to each token.
  # This assumes the input had only
  # css classes defined for each element,
  # and not inline styles,
  #
  pushIfTrue = (array, functionResult) ->
    if functionResult
      array.push(functionResult)
      return true
    return false

  #
  # Enrich with computes styles.
  # E.g. whether the word is all uppercase.
  #
  for token in tokens
    if token.metaType is 'regular'
      token.calculatedProperties = []
      if pushIfTrue(token.calculatedProperties, ctype.testPureUpperCase(token.text))
        console.log('pushed one computed style')

  #
  # Augment each token with its final calculated styles as well as position information.
  # E.g. read the css style definitions, of the css classes assigned to a token, 
  # and add them to the token.
  #
  for token in tokens 

    token.finalStyles = {}
    token.positionInfo = {}

    for cssClass in token.styles  # iterate over each css class indicated for the token,
                                  # adding its final style definitions to the token
      styles = css.getFinalStyles(cssClass, inputStylesMap)
      if styles? 
        for style in styles 
          if util.isAnyOf(style.property, css.positionData) # is position info? or is it real style?
            token.positionInfo[style.property] = style.value
          else
            token.finalStyles[style.property] = style.value
    
      if util.objectPropertiesCount(token.finalStyles) is 0
        console.warn('No final styles applied to token')
        console.dir(token)

  #
  # Mark tokens that are a beginning of a line
  # TODO: parameterize direction to support RTL languages
  #
  tokens[0].lineLocation = 'opener'
  tokens.reduce (a, b) ->                             
    if parseInt(b.positionInfo.bottom) < parseInt(a.positionInfo.bottom)  # later is more downwards than former
      if parseInt(b.positionInfo.left) < parseInt(a.positionInfo.left)    # later is leftwards to former (assumes LTR language)
        b.lineLocation = 'opener'                     # assume its a line opener word
        console.log(b.text)
    return b

  #
  # Create sentences sequence
  #
  util.timelog('Sentence tokenizing')
  connect_token_group = ({group, token}) ->   # using named arguments here..
    group.push(token)
    token.partOf = group      

  abbreviations = 0
  groups = [] # sequence of all groups
  group = []  
  for token in tokens
    if token.type = 'regular' 
      connect_token_group({group:group, token:token})
      if token.text is '.'             # Is this a sentence splitter?
        unless group.length > (1 + 1)  # One word and then a period are not a 'sentence', 
          abbreviations += 1           # likely it is an abbreviation. Not a sentence split..
        else
          groups.push(group) # close off a 'sentence' group
          group = []
  unless group.length is 0  # Close off trailing bits of text if any, 
    groups.push(group)      # as a group, whatever they are. For now.
  util.timelog('Sentence tokenizing')                       

  documentQuantifiers = {}
  documentQuantifiers['sentences']                    = groups.length
  documentQuantifiers['period-trailed-abbreviations'] = abbreviations
  console.dir(documentQuantifiers)

  #
  # Utility function for logging frequencies  
  # of values appearing in a certain named property 
  # appearing under a certain object included in a token.
  #
  # E.g. for calculating frequencies of styles.
  #
  # Parameters:
  #
  # objectsArray        - the array of tokens
  # filterKey, filterBy - condition to filter from the array by
  # property            - which property to get the frequency of its values
  # parentProperty      - the parent of that property in the token object
  #
  frequencies = (objectsArray, filterKey, filterBy, property, parentProperty) ->
    map = {}
    for object in objectsArray when object[filterKey] is filterBy
      for key, value of object[parentProperty] 
        if key is property 
          value = parseFloat(value)
          if map[value]?
            map[value] += 1
          else
            map[value] = 1

    array = []
    for key, val of map
      array.push({key, val})
    array.sort( (a, b) -> return parseFloat(b.val) - parseFloat(a.val) )

    console.dir array[i] for i in [0..39] when array[i]?

  #frequencies(tokens, 'metaType', 'regular', 'left', 'positionInfo')
  #frequencies(tokens, 'metaType', 'regular', 'font-size', 'finalStyles')  

  ###
  util.timelog('location analysis')                       
  #
  # Some location analytics - prior to generalizing it
  #
  leftPositions = {}
  for token in tokens when token.metaType is 'regular'
    for positionProperty, value of token.positionInfo 
      if util.isAnyOf(positionProperty, ['left']) 
        value = parseInt(value)
        if leftPositions[value]?
          leftPositions[value] += 1
        else
          leftPositions[value] = 1

  leftPosArray = []
  for position, frequency of leftPositions
    leftPosArray.push({position, frequency})
  leftPosArray.sort( (a, b) -> return parseFloat(b.frequency) - parseFloat(a.frequency) )
  util.timelog('location analysis')                                 

  console.dir leftPosArray[i] for i in [0..39]
  ###
  
  #
  # Some word frequency analytics.
  # Should incorporate (or build from our own inputs!) a corpus of 'stop-words',
  # to filter out common English (or any detected language) terms, 
  # when this analytic is really going to be used..
  #
  # In addition, should check for frequency of sequences too, in order to
  # at a somewhat higher level catch frequent two-word concepts
  #
  # A stemmer may also be incorporated after giving it some thought
  # concerning what can be done in real-time and what can be only
  # left for longer-range analytics
  # 
  util.timelog('Calculating word frequencies')
  wordFrequencies = {}
  for token in tokens when token.metaType is 'regular'
    # won't hurt filtering out punctuation as well
    word = token.text 
    if wordFrequencies[word]? 
      wordFrequencies[word] += 1
    else 
      wordFrequencies[word] = 1
  util.timelog('Calculating word frequencies')   

  util.timelog('Sorting frequencies')
  wordFrequenciesArray = []
  for word, frequency of wordFrequencies
    wordFrequenciesArray.push({word, frequency})
  wordFrequenciesArray.sort( (a, b) -> return parseInt(b.frequency) - parseInt(a.frequency) )
  util.timelog('Sorting frequencies')
  #console.dir wordFrequenciesArray[i] for i in [0..39]


  # Send back the outcome
  outputHtml = html.buildOutputHtml(tokens, inputStylesMap)
  output.serveOutput(outputHtml, name, res)

  