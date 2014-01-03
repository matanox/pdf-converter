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

  sampletext = 
    '<!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf8"/>
        <title>Page Title</title>
      </head>
      <body>
        <a href="https://github.com/ForbesLindesay">
          <img src="/static/forkme.png" alt="Fork me on GitHub">
        </a>
        <div class="row">
          <div class="large-12 columns">
            <h1 id="page-title">Page Title</h1>
            <p>This is a demo page</p>
          </div>
        </div>
        <script src="/static/client.js"></script>
      </body>
    </html>'

  htmlparser = require("htmlparser2");
  util.timelog('htmlparser2') 
  handler = new htmlparser.DomHandler((error, dom) ->
    if (error)
      console.log('htmlparser2 failed loading document')
    else
      console.log('htmlparser2 loaded document')
  )
  parser = new htmlparser.Parser(handler)
  parser.parseComplete(rawHtml)
  dom = handler.dom
  #console.log(dom)
  util.timelog('htmlparser2') 

  ###
  # jsdom is excruciatingly slow to load
  # maybe it pays off in quicker processing after the loading or less memory?...
  jsdom = require("jsdom").jsdom
  util.timelog('jsdom')
  doc = jsdom(rawHtml)
  util.timelog('jsdom')

  util.timelog('jsdom')
  doc2 = jsdom(rawHtml)
  util.timelog('jsdom')

  # Alternative method of it that never worked for me
  jsdom.env(rawHtml, [], [], (errors, window) ->
    console.log('inside')
    console.log(errors)    
    console.log(window.body)
  )
  ###  

  #process.exit(0)

  # Keep divs without their wrapping div if any.
  #rawRelevantDivs = html.removeOuterDivs(rawHtml)

  # Create array of objects holding the text and style of each div
  #divsWithStyles = (html.representNodeOld div for div in rawRelevantDivs)

  # For now, remove any images, brute force. This code will not persist
  # And is not sufficient for also removing their text overlay
  #divsWithStyles = filterImages(divsWithStyles)

  # For now, extract all text inside each div, indifferently to 
  # what's directly included v.s. what's nested in spans - 
  # all text is equally concatenated.
  #html.stripSpanWrappers(div) for div in divsWithStyles

  # Discard any divs that contain zero-length text
  #nodesWithStyles = filterZeroLengthText(divsWithStyles)

  #divsNum = divsWithStyles.length
  # endsSpaceDelimited = 0
  # If most divs end with a delimiting space character, then we don't need
  # to implicitly infer a delimiter at the end of each div, otherwise we do.
  # The use of a constant ratio test is extremely coarse and temporary,
  # a refined solution should replace it.
  #console.log(endsSpaceDelimited)
  #console.log(endsSpaceDelimited / divsNum)
  #if (endsSpaceDelimited / divsNum) < 0.3 then augmentEachDiv = true else augmentEachDiv = false

  nodesWithStyles = html.representNodes(dom)

  ###
  # Now tokenize (from text into words, punctuation, etc.),
  # while inheriting the style of the div to each resulting token
  tokens = []
  for node in nodesWithStyles
    tokens = html.tokenize(node.text)
    for subToken in tokens 
      switch subToken.metaType
        when 'regular' then subToken.styles = node.styles
    tokens.push(nodeTokens)
  ###

  tokenArrays = (html.tokenize node for node in nodesWithStyles)

  #console.log(node)

  # Flatten to one-dimensional array of tokens...
  tokens = []
  for tokenArray in tokenArrays
    for token in tokenArray
      tokens.push(token)

  # Smooth out styles such that each delimiter 
  # inherits the style of its preceding token. 
  # May belong either here or inside the core tokenization...
  tokens.reduce (x, y) -> 
    if y.metaType is 'delimiter' then y.stylesArray = x.stylesArray
    return y

  # TODO: duplicate to unit test
  for token in tokens when token.metaType == 'regular'
    if token.text.length == 0
      throw "Error - zero length text in data"

  if tokens.length == 0
    console.log("No text was extracted from input")
    throw("No text was extracted from input")

  #
  # Augment each token with its final calculated styles as well as position information.
  # E.g. read the css style definitions, of the css classes assigned to a token, 
  # and add them to the token.
  #
  #console.log(tokens)  
  for token in tokens 
    #console.dir(token)
    token.finalStyles = {}
    token.positionInfo = {}

    for cssClasses in token.stylesArray  # cascade the styles from each parent node 
      #console.log cssClasses
      for cssClass in cssClasses         # iterate over each css class indicated for the token,
                                         # adding its final style definitions to the token
        #console.log cssClass                                         
        styles = css.getFinalStyles(cssClass, inputStylesMap)
        if styles? 
          #console.log(styles)
          for style in styles 
            if util.isAnyOf(style.property, css.positionData) # is position info? or is it real style?
              token.positionInfo[style.property] = style.value
            else
              token.finalStyles[style.property] = style.value
      
    if util.objectPropertiesCount(token.finalStyles) is 0
      console.warn('No final styles applied to token')
      console.dir(token)

  #
  # Mark tokens that begin or end their line
  # TODO: parameterize direction to support RTL languages
  #
  util.first(tokens).lineLocation = 'opener'
  tokens.reduce (a, b) ->                             
    if parseInt(b.positionInfo.bottom) < parseInt(a.positionInfo.bottom)  # later is more downwards than former
      #if parseInt(b.positionInfo.left) < parseInt(a.positionInfo.left)    # later is leftwards to former (assumes LTR language)
      b.lineLocation = 'opener'       # a line opener                   
      a.lineLocation = 'closer'       # a line closer       
     
      #console.log('closer: ' + a.text)
      #console.log('opener: ' + b.text)

    return b
  util.last(tokens).lineLocation = 'closer'

  iterator = (tokens, iterationFunc) ->
    i = 1
    while i < tokens.length
      a = tokens[i-1]
      b = tokens[i]
      i = i + iterationFunc(a, b, i, tokens) 

  #
  # Handle end-of-line tokenization aspects: 
  # 1. Delimitation augmentation
  # 2. Uniting hyphen-split words (E.g. 'associa-', 'ted' -> 'associated')
  #
  console.log(tokens.length)
  iterator(tokens, (a, b, i, tokens) ->                             
    if b.lineLocation is 'opener'       
      if a.lineLocation is 'closer'       
        if a.metaType is 'regular' # line didn't include an ending delimiter 
          #console.log('undelimited end of line detected')
          # if detected, unite a line boundary 'hypen-split'
          if util.endsWith(a.text, '-')
            a.text = a.text.slice(0, -1)   # discard the hyphen
            a.text = a.text.concat(b.text) # concatenate text of second element into first
            tokens.splice(i, 1)            # remove second element
            return 0
  
          # add a delimiter at the end of the line, unless a hyphen-split 
          # was just united, in which case it's not necessary
          else
            if a.text is 'approach' and b.text is 'to'         
              console.log('found at ' + i)
            newDelimiter = {'metaType': 'delimiter'}
            newDelimiter.styles = a.styles
            newDelimiter.finalStyles = a.finalStyles    
            tokens.splice(i, 0, newDelimiter) # add a delimiter in this case
            return 2
    return 1)

  #console.log(tokens.length)
  #util.logObject(tokens)
  #for token in tokens 
  #  console.log(token.metaType)

  #
  # Unite token couples that have no delimiter in between them,
  # the first of which ending with '-' (while applying the
  # styles of the first one to both).
  #
  # Note: this should also unite triples and so on, not just couples
  #
  tokens.reduce (a, b, index) -> 
    if a.metaType is 'regular' and b.metaType is 'regular'

      if util.endsWith(a.text, '-')
        a.text = a.text.slice(0, -1)   # discard the hyphen
        a.text = a.text.concat(b.text) # concatenate text of second element into first
        tokens.splice(index, 1)        # remove second element
        return a
    return b
  
  #console.log(tokens.length)

  util.timelog('Extraction from html stage A')

  # Add unique ids to tokens - after all uniting of tokens already took place
  id = 0
  for token in tokens
    token.id = id
    id += 1

  #
  # Enrich with computes styles.
  # For now one enrichment type - whether the word is all uppercase.
  #
  for token in tokens
    if token.metaType is 'regular'
      token.calculatedProperties = []
      if util.pushIfTrue(token.calculatedProperties, ctype.testPureUpperCase(token.text))
        console.log('pushed one computed style')

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

    #console.dir array[i] for i in [0..39] when array[i]?

  frequencies(tokens, 'metaType', 'regular', 'left', 'positionInfo')
  frequencies(tokens, 'metaType', 'regular', 'font-size', 'finalStyles')  

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

  