fs      = require 'fs'
util    = require '../util'
logging = require '../logging' 
timer   = require '../timer'
css     = require '../css'
html    = require '../html'
model   = require '../model'
output  = require '../output'
ctype   = require '../ctype'
markers = require '../markers'
verbex  = require 'verbal-expressions'

iterator = (tokens, iterationFunc) ->
  i = 1
  while i < tokens.length
    a = tokens[i-1]
    b = tokens[i]
    i = i + iterationFunc(a, b, i, tokens) 


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
exports.go = (req, name, res ,docLogger) ->

  util.timelog('Extraction from html stage A')

  # Read the input html 
  path = '../local-copies/' + 'html-converted/' 
  #name = req.query.name
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString()

  # Extract all style info 
  inputStylesMap = css.simpleFetchStyles(rawHtml ,path + name + '/') 

  htmlparser = require("htmlparser2");
  util.timelog('htmlparser2') 
  handler = new htmlparser.DomHandler((error, dom) ->
    if (error)
      docLogger.error('htmlparser2 failed loading document')
    else
      docLogger.info('htmlparser2 loaded document')
  )
  parser = new htmlparser.Parser(handler)
  parser.parseComplete(rawHtml)
  dom = handler.dom
  #docLogger.info(dom)
  util.timelog 'htmlparser2', docLogger 
 
  # Discard any divs that contain zero-length text
  #nodesWithStyles = filterZeroLengthText(divsWithStyles)

  #divsNum = divsWithStyles.length
  # endsSpaceDelimited = 0
  # If most divs end with a delimiting space character, then we don't need
  # to implicitly infer a delimiter at the end of each div, otherwise we do.
  # The use of a constant ratio test is extremely coarse and temporary,
  # a refined solution should replace it.
  #docLogger.info(endsSpaceDelimited)
  #docLogger.info(endsSpaceDelimited / divsNum)
  #if (endsSpaceDelimited / divsNum) < 0.3 then augmentEachDiv = true else augmentEachDiv = false

  nodesWithStyles = html.representNodes(dom)

  tokenArrays = (html.tokenize node for node in nodesWithStyles)

  #docLogger.info(node)

  # Flatten to one-dimensional array of tokens...
  tokens = []
  for tokenArray in tokenArrays
    for token in tokenArray
      tokens.push(token)

  if tokens.length == 0
    docLogger.error("No text was extracted from input")
    console.info("No text was extracted from input")
    res.writeHead 505
    res.write 'We are sorry but the pdf you uploaded ' + '(' + name + ')' + ' cannot be processed. We are working on finding a better copy of the same article and will get back to you with it.' 
    res.end()
    return false
    #throw("No text was extracted from input")

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

  #
  # Augment each token with its final calculated styles as well as position information.
  # E.g. read the css style definitions, of the css classes assigned to a token, 
  # and add them to the token.
  #
  #docLogger.info(tokens)  
  for token in tokens 
    #console.dir(token)
    token.finalStyles = {}
    token.positionInfo = {}

    for cssClasses in token.stylesArray  # cascade the styles from each parent node 
      #docLogger.info cssClasses
      for cssClass in cssClasses         # iterate over each css class indicated for the token,
                                         # adding its final style definitions to the token
        #docLogger.info cssClass                                         
        styles = css.getFinalStyles(cssClass, inputStylesMap)
        if styles? 
          #docLogger.info(styles)
          for style in styles 
            if util.isAnyOf(style.property, css.positionData) # is position info? or is it real style?
              token.positionInfo[style.property] = style.value
            else
              token.finalStyles[style.property] = style.value
      
    if util.objectPropertiesCount(token.finalStyles) is 0
      docLogger.warn('No final styles applied to token')
      docLogger.warn(token)

  #
  # Find repeat header and footer text
  # 
  util.timelog 'remove repeat headers'

  # Get topmost and bottom-most text position
  maxTop    = 0
  maxBottom = 100000
  for token in tokens
    bottom = parseInt(token.positionInfo.bottom)
    if bottom < maxBottom
      maxBottom = bottom
    if bottom > maxTop
      maxTop = bottom
      
  console.log maxTop
  console.log maxBottom

  # Create an array of all sequences appearing at that topmost location

  topSequences = [] # Array of same row topmost elements 

  topSequence = []
  iterator(tokens, (a, b, i, tokens) ->
      if parseInt(a.positionInfo.bottom) is maxTop
        topSequence.push(a)
        if parseInt(b.positionInfo.bottom) isnt maxTop
          # flush
          topSequences.push(topSequence)
          topSequence = []
      return 1 # go one position forward
    ) 

  for physicalPageSide in [0..1] # Once for left-hand pages, and once for right-hand ones
    topRepeatSequence = 0
    for i in [physicalPageSide..topSequences.length-1-2] by 2
      a = topSequences[i]
      b = topSequences[i+2]

      #console.log a.length
      #console.log b.length

      # Is it a sequence repeating across two pages, at the top of them?
      repeat = true
      if a.length is b.length
        for t in [0..a.length-1]
          unless ((b[t].text is a[t].text) or (Math.abs(parseInt(b[t].text) - parseInt(a[t].text)) is 2)) # are they the same or one number apart?
            repeat = false
            
      # Mark the sequence as fluff in both pages?
      if repeat 
        for t in [0..a.length-1]
          a[t].fluff = true
          b[t].fluff = true
        topRepeatSequence +=1
      
    console.log topRepeatSequence

  # Now effectively remove the identified repeat sequences
  filtered = []
  for t in [0..tokens.length-1]
    unless tokens[t].fluff?
      filtered.push(tokens[t])
  tokens = filtered

  util.timelog 'remove repeat headers'

  #
  # Mark tokens that begin or end their line 
  # and generally handle implications of row beginnings.
  #
  # This function has few logical holes in it:
  #
  # TODO: parameterize direction to support RTL languages
  # TODO: this code assumes postions are given in .left and .bottom not .right and .top or other
  # TODO: this code compares position on an integer rounding basis, this is only usually correct
  # TODO: this code assumes the size unit is px and some more 
  #
  util.first(tokens).lineLocation = 'opener'

  lastRowPosLeft = null  # a closure
  tokens.reduce (a, b, i, tokens) ->                             

    sameRow = true
  
    # Identify and handle new text column
    # By examining height difference between consequtive words
    if parseInt(b.positionInfo.bottom) > parseInt(a.positionInfo.bottom) + 100
      sameRow = false
      a.lineLocation = 'closer'       # a line closer       
      b.lineLocation = 'opener'       # a line opener 
      lastRowPosLeft = b.positionInfo.left  # recalibrate for forthcoming new paragraph beginning

    # Identify and handle new paragraph
    # By examining height difference between consequtive words and some more
    if parseInt(b.positionInfo.bottom) + 5 < parseInt(a.positionInfo.bottom) 
      sameRow = false
      a.lineLocation = 'closer'       # a line closer       
      b.lineLocation = 'opener'       # a line opener                         
      #docLogger.info('closer: ' + a.text)
      #docLogger.info('opener: ' + b.text)
      
      if lastRowPosLeft?
        # Is there a new paragraph indentation shift?
        if parseInt(b.positionInfo.left) > parseInt(lastRowPosLeft)
          a.paragraph = 'closer'
          b.paragraph = 'opener'   

        # Is it a new line with a larger line space?
        if parseInt(b.positionInfo.bottom) + 12 < parseInt(a.positionInfo.bottom) 
          a.paragraph = 'closer'
          b.paragraph = 'opener'   

      lastRowPosLeft = b.positionInfo.left

    if sameRow
      # Identify and handle superscript and subscript
      if Math.abs(parseInt(b.positionInfo.bottom) - parseInt(a.positionInfo.bottom)) > 0
        # Add a delimiter so that a differently vertically-positioned token pair isn't combined into a single token
        # This can later be refined to reflect this is not a regular space delimiter,
        # as well as enable propagating the relative font size and height of the super/subscript.
        newDelimiter = {'metaType': 'delimiter'}
        newDelimiter.styles = a.styles
        newDelimiter.finalStyles = a.finalStyles    
        tokens.splice(i, 0, newDelimiter) # add a delimiter in this case

    return b

  util.last(tokens).lineLocation = 'closer'

  #
  # Handle end-of-line tokenization aspects: 
  # 1. Delimitation augmentation
  # 2. Uniting hyphen-split words (E.g. 'associa-', 'ted' -> 'associated')
  #
  docLogger.info(tokens.length)
  iterator(tokens, (a, b, i, tokens) ->                             
    if b.lineLocation is 'opener'       
      if a.lineLocation is 'closer'       
        if a.metaType is 'regular' # line didn't include an ending delimiter 
          #docLogger.info('undelimited end of line detected')
          # if detected, unite a line boundary 'hypen-split'
          if util.endsWith(a.text, '-')
            a.text = a.text.slice(0, -1)   # discard the hyphen
            a.text = a.text.concat(b.text) # concatenate text of second element into first
            tokens.splice(i, 1)            # remove second element
            return 0
  
          # add a delimiter at the end of the line, unless a hyphen-split 
          # was just united, in which case it's not necessary
          else
            newDelimiter = {'metaType': 'delimiter'}
            newDelimiter.styles = a.styles
            newDelimiter.finalStyles = a.finalStyles    
            tokens.splice(i, 0, newDelimiter) # add a delimiter in this case
            return 2
    return 1)

  #
  # Unite tokens that do not have a delimiter in between them.
  # This is necessary for the cases where pdf2html splits parts of 
  # the same word between span elements. 
  #
  # (Should it actually better be part of the html level tokenization?)
  #
  iterator(tokens, (a, b, index, tokens) -> 
    if a.metaType is 'regular' and b.metaType is 'regular'

      # Merge the two tokens - styles from first, paragraph status from second
      a.text = a.text.concat(b.text) # concatenate text of second element into first
      a.paragraph = b.paragraph

      tokens.splice(index, 1)        # remove second element
      return 0
    return 1)

  #docLogger.info(tokens.length)

  util.timelog 'Extraction from html stage A', docLogger

  # Add unique ids to tokens - after all uniting of tokens already took place
  util.timelog('ID seeding')        
  id = 0
  for token in tokens
    token.id = id
    id += 1
  util.timelog 'ID seeding', docLogger

  # Create a sorted index
  textIndex = []
  for token in tokens when token.metaType is 'regular'
    textIndex.push({text: token.text, id: token.id})
  util.timelog('Index creation')    
  textIndex.sort((a, b) ->  # simple sort by lexicographic order obliviously of the case of equality
    if a.text > b.text
      return 1
    else
      return -1)
  util.timelog 'Index creation', docLogger      
  #docLogger.info textIndex

  ###
  markersRegex = ''
  
  for m in [0..markers.markers.array.length-1]
    markerText = markers.markers.array[m].WordOrPattern
    markerRegex = ''

    unless m is 40 then markersRegex += "|"  # add logical 'or' to regex 

    if markers.anything.test(markerText)
      docLogger.info('in split for: ' + markerText)
      splitText = markerText.split(markers.anything)
      for s in [0..splitText.length-1]
        unless s is 0 then markerRegex += '|'    # add logical 'or' to regex 
        if markers.anything.test(splitText[s])
          markerRegex += '\s'                    # add logical 'and then anything' to regex
          docLogger.info('anything found')
        else
          markerRegex += splitText[s]            # add as-is text to the regex
          docLogger.info('no anything marker')
    else
      markerRegex += markerText


    markersRegex += markerRegex
    #docLogger.info(markerText)
    #docLogger.info(markerRegex.source)
    docLogger.info(markersRegex)

    
    util.timelog('Markers visualization') 
    #docLogger.info('Marker regex length is ' + markersRegex.toString().length)
    #docLogger.info(markersRegex.source)
    #testverbex = verbex().then("verbex testing sentence").or().then("and more")
    #docLogger.info(testverbex.toRegExp().source)
    ###

  docSieve = markers.createDocumentSieve(markers.baseSieve)
  #util.logObject(docSieve)

  #
  # Enrich with computes styles.
  # For now one enrichment type - whether the word is all uppercase.
  #
  for token in tokens
    if token.metaType is 'regular'
      token.calculatedProperties = []
      if util.pushIfTrue(token.calculatedProperties, ctype.testPureUpperCase(token.text))
        docLogger.info('All Caps Style detected for word: ' + token.text);
      if util.pushIfTrue(token.calculatedProperties, ctype.testInterspacedTitleWord(token.text))
        docLogger.info('Interspaced Title Word detected for word: ' + token.text)


  #
  # Create sentences sequence
  # Temporary note: For now, each sentence will be tokenized to have its tokens become an array
  #                 inside the groups array. Later, there can be more types of groups etc..
  #
  util.timelog('Sentence tokenizing')
  connect_token_group = ({group, token}) ->   # using named arguments here..
    group.push(token)
    #token.partOf = group      

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
  util.timelog 'Sentence tokenizing', docLogger  

  # Log some statistics about sentences
  documentQuantifiers = {}
  documentQuantifiers['sentences']                    = groups.length
  documentQuantifiers['period-trailed-abbreviations'] = abbreviations
  console.dir(documentQuantifiers)

  #
  # Adding marker highlighting
  #
  util.timelog('Markers visualization') 
  
  # Rather than a loop (formerly: for sentence in groups),
  # iterate the sentences such that each sentence queues handling 
  # of the next one on the call stack. So that this cpu intensive bit doesn't block the process
  markSentence = (sentenceIdx) ->
    #docLogger.info(sentenceIdx)
    sentence = groups[sentenceIdx]
    matchedMarkers = []
    if sentence?
      for token in sentence when token.metaType isnt 'delimiter'  # for each text token of the sentence
        for marker in docSieve
          #docLogger.info (marker.nextExpected.toString() + ' ' + token.text + 'v.s.'+ marker.markerTokens[marker.nextExpected].text)
          switch marker.markerTokens[marker.nextExpected].metaType
            when 'regular' 
              
              if token.text is marker.markerTokens[marker.nextExpected].text
                if marker.nextExpected is (marker.markerTokens.length - 1)     # is it the last token of the marker?
                  #docLogger.info('whole marker matched: ' + console.dir(marker))
                  matchedMarkers.push(marker)
                  token.emphasis = true
                  marker.nextExpected = 0
                else
                  #docLogger.info('marker token matched ')
                  marker.nextExpected += 1
              else 
                unless marker.markerTokens[marker.nextExpected].metaType is 'anyOneOrMore'
                  marker.nextExpected = 0  # out of match for this marker

            when 'anyOneOrMore'
              if marker.nextExpected is (marker.markerTokens.length - 1)       # is it the last token of the marker?
                marker.nextExpected = 0    # out of match for this marker
              else 
                if token.text is marker.markerTokens[marker.nextExpected + 1].text 
                  if (marker.nextExpected + 1) is (marker.markerTokens.length - 1)
                    #docLogger.info('whole marker matched after wildcard: ' + console.dir(marker))
                    matchedMarkers.push(marker)
                    token.emphasis = true
                    marker.nextExpected = 0
                  else
                    marker.nextExpected += 2

      sentenceIdx += 1
      if sentenceIdx < groups.length
        setImmediate(() -> markSentence(sentenceIdx)) # queue handling of the next sentence while 
                                                        # allowing IO to occur in between (http://nodejs.org/api/timers.html#timers_setimmediate_callback_arg)
      else 
        util.timelog 'Markers visualization', docLogger

        # Done. Send back response, after attaching the result data to the session
        util.timelog 'pickling'
        #req.session.tokens = require('circular-json').stringify(tokens) # takes 100 times longer than JSON.stringify so can't afford it
        req.session.tokens = JSON.stringify(tokens)
        console.log req.session.tokens.length
        util.timelog 'pickling'
        #console.log req.session.tokens
        outputHtml = html.buildOutputHtml(tokens, inputStylesMap, docLogger)        
        output.serveOutput(outputHtml, name, res, docLogger)

    else
      console.error 'zero length sentence registered'
      console.error sentenceIdx
      console.error groups.length
      console.error name

  markSentence(0) # start the iteration over sentences. 
                  # Each one queues the next. Last one passes over to the next phase.

    #if matchedMarkers.length > 0
      #util.logObject(matchedMarkers)
      #util.logObject(sentence)
      #docLogger.info()
      #for token in sentence
        #token.finalStyles['color'] = 'red'  # overide the color
  

  