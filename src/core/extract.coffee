#
# Main part of this application
# Drive the rich tokenization of text from html input
# Extracts and normalizes text content from html (with css styles)
#

#verbex           = require 'verbal-expressions'
assert           = require 'assert' 
fs               = require 'fs'
css              = require './css'
html             = require './html'
sentenceSplitter = require './sentenceSplitter'
markers          = require './markers'
util             = require '../util/util'
logging          = require '../util/logging' 
timer            = require '../util/timer'
ctype            = require '../util/ctype'
analytic         = require '../util/analytic'
dataWriter       = require '../data/dataWriter'
refactorTools    = require '../refactorTools'
headers          = require './headers/headers'
xml              = require '../data/xml'
nconf            = require('nconf')

nconf = require('nconf')
JATSoutPath = (require '../storage/localManagedFiles').rooted(nconf.get("locations")["pdf-source-extraction"]["JATS"])
TextoutPath = (require '../storage/localManagedFiles').rooted(nconf.get("locations")["pdf-source-extraction"]["Text"])

mode = 'basic'
refactorMode = true
createIndex = false # no use for the words index right now here

#
# Helper function for iterating token pairs
#

iterator = (tokens, iterationFunc) ->
  i = 1
  while i < tokens.length
    a = tokens[i-1]
    b = tokens[i]
    i = i + iterationFunc(a, b, i, tokens) 


UnplausiblyAbstract = (tokens, sequence) -> 

  sum = (a,b) -> a + b

  textTokens = []
  for t in [sequence.startToken..sequence.endToken] when tokens[t].text?
    textTokens.push tokens[t]

  #textTokens.map((t) -> console.log(t.text + '\n'))

  upperCaseStarts = textTokens.map((t) => if ctype.isUpperCaseChar(t.text.charAt(0)) then 1 else 0).reduce(sum)

  includesComma = textTokens.map((t) => 
    if t.text.indexOf(',') >= 0 then 1 else 0).reduce(sum)

  if upperCaseStarts > 1/3 * textTokens.length then return true
  if includesComma   > 1/4 * textTokens.length then return true

  return false

#
# extract article title and abstract
#
titleAndAbstract = (context, tokens) ->
  name = context.name

  util.timelog(context, 'Title and abstract recognition')

  # 
  # get first page tokens
  #
  firstPage = []
  for token in tokens
    if token.page is '1'
      firstPage.push token
    else 
      break

  for t in [0..tokens.length-1]
    if parseFloat(tokens[t].page) > 1
      firstPageEnd = t-1
      break

  if not firstPageEnd?
    throw 'failed detecting end of first page'    

  dataWriter.write context, 'stats',  'first page is ' + firstPageEnd + ' tokens long'

  #
  # Get all font sizes across the entire document - shouldn't this be just from the first page??!?
  #
  fontSizes = []
  for token in tokens
    fontSizes.push parseFloat(token.finalStyles['font-size'])

  fontSizesDistribution = analytic.generateDistribution(fontSizes)

  logging.cond "distribution of input font sizes:", 'fonts'
  logging.cond fontSizesDistribution, 'fonts'

  mainFontSize = parseFloat(util.first(fontSizesDistribution).key) 

  #
  # Figure line beginnings and endings - currently not in use
  #
  # Note: unlike core text, here we don't expect intricacies like
  # two or more text columns for the same text sequence
  #
  lineOpeners = []
  for t in [1..tokens.length-1] when parseInt(tokens[t].page) is 1
    a = tokens[t-1]
    b = tokens[t]
    if parseFloat(b.positionInfo.bottom) + 5 < parseFloat(a.positionInfo.bottom) 
      a.lineCloser = true       # a line closer  
      b.lineOpener = true       # a line opener    
      lineOpeners.push(t)  # pushes the index of b

  #
  # Derive text sequences
  #
  sequences = []

  sequence = 
    'font-size':   tokens[0].finalStyles['font-size'],
    'font-family': tokens[0].finalStyles['font-family'],
    'startToken':  0,
    'startLeft':   parseFloat(tokens[0].positionInfo.left),
    'startBottom': parseFloat(tokens[0].positionInfo.bottom)

  #
  # Loop to bunch tokens into text sequences
  #
  for t in [1..firstPageEnd]

    token = tokens[t]
    prev  = tokens[t-1]
    split = false

    if token.lineOpener
      rowLeftLast = rowLeftCurr
      rowLeftCurr = parseFloat(token.positionInfo.left)
      #lineSpaces.push parseFloat(a.positionInfo.bottom) - parseFloat(b.positionInfo.bottom)

    ###
    #
    # Considers splitting by typography and horizontal distance from previous
    #
  
    Let us try doing without considering font change as a sequence splitter and relying
    on more salient ones, as most sequences should/would defer by location anyway.
    since typography is allowed to change inside an abstract...

    # does the font defer in font, compared to current sequence?
    if (token.finalStyles['font-size'] isnt sequence['font-size']) or 
    (token.finalStyles['font-family'] isnt sequence['font-family'])
      #
      # if so, is it on the same row though? 
      # the math on this line tries to approximate whether the current token
      # is just a superscript/subscript offset away or really a different line 
      unless Math.abs(parseFloat(prev.positionInfo.bottom) - parseFloat(token.positionInfo.bottom)) < parseFloat(prev.finalStyles['font-size'])*0.25
        logging.logRed Math.abs(parseFloat(prev.positionInfo.bottom) - parseFloat(token.positionInfo.bottom)) 
        logging.logRed parseFloat(prev.finalStyles['font-size'])*0.25
        # does it have the same horizontal start location as the previous row?
        unless (token.lineOpener and Math.abs(rowLeftLast - rowLeftCurr) < 2)  # allow some grace....
          #
          # well, getting here, this should probably be the beginning of a new sequence
          #
          split = true
    ###

    #
    # Considers splitting by vertical distance from previous
    #
    # Note: this is a terrible hack and it needs to refine by better fathoming the relationship 
    # between actual visual pixel line spacing, v.s. the play between the height, font-size, bottom css 
    # properties, and the css transform matrix as used in pdf2htmlEX output. 
    #
    # NOTE: 0.25 is the css transform matrix horizontal and vertical scaling factor, used
    #       by pdf2htmlEX css. i.e. actual font pixel size is 0.25 of the declared 
    #       font-size property.
    #
    if Math.abs(parseFloat(prev.positionInfo.bottom) - parseFloat(token.positionInfo.bottom)) > parseFloat(token.finalStyles['font-size'])*0.25*1.5
      split = true
    
    if split
      #console.dir token
      # close off terminated sequence       
      sequence.endToken    = t-1  
      sequence.numOfTokens = sequence.endToken - sequence.startToken + 1
      sequences.push sequence
      #util.flattenSequenceText(tokens, sequence, 'detected sequence')

      # start next sequence
      sequence = 
        'font-size':   token.finalStyles['font-size'],
        'font-family': token.finalStyles['font-family'],
        'startToken':  t,
        'startText':   token.text # for easing debug orientation
        'startLeft':   parseFloat(token.positionInfo.left),
        'startBottom': parseFloat(token.positionInfo.bottom)
 
  # close off last sequence
  if not sequence.endToken
    sequence.endToken    = firstPageEnd  
    sequence.numOfTokens = sequence.endToken - sequence.startToken + 1
    sequences.push sequence

  # sort sequences from top to bottom, then from left to right
  sequences.sort( 
    (a, b) -> 
      # is same vertical location, sort by horizontal location
      if b.startBottom is a.startBottom # consider adding 'grace' here
        return a.startLeft - b.startLeft

      # sort by vertical location
      return b.startBottom - a.startBottom 
    )


  # Great way to log all detected first page sequences!
  logFirstPageSequences = () ->
    for sequence, s in sequences
      console.log s
      console.log sequence.startBottom
      logging.logBlue util.flattenSequenceText(tokens, sequence)
  
  logFirstPageSequences()

  minAbstractTokensNum    = 100  # this includes delimiters, so approx. 50 words
  minTitleTokensNum       = 6    # this includes delimiters too

  #
  # Detect the title 
  #
  # looks for first sequence, from top to bottom, that starts with 
  # a large font and is longer than some minimum value. The algorithm
  # moves from largest font to next largest font and so forth, 
  # until a long enough sequence is detected.
  # 
  # Note: this assumes that the title uses a single font.
  #       

  # sort fonts descending 
  fontSizesUnique = util.unique(fontSizes, true)
  fontSizesUnique.sort( (a, b) -> return b - a )  
  #console.dir fontSizesUnique

  i = 0  # look for largest font size sequence
  until title? or i>2 # if no minimally long title is found with the largest font,
                      # try the next largest, arguably heuristic but seems to work.

    for sequence in sequences   # get sequence using it
      #console.log parseFloat(sequence['font-size']) + ' ' + fontSizesUnique[i]
      #console.log sequence.startBottom
      #util.flattenSequenceText(tokens, sequence, 'sequence')
      if parseFloat(sequence['font-size']) is fontSizesUnique[i]
        #console.log sequence.numOfTokens
        if sequence.startBottom > 500
          if sequence.numOfTokens > minTitleTokensNum
            title = sequence

    i += 1  # look for next largest font size sequence

  #
  # get abstract by looking for the header 'abstract'
  #

  skipDelimiters = (tokens, startToken, endToken) ->
    for t in [startToken..endToken]
      if tokens[t].metaType is 'regular'
        return tokens[t]

    return null

  ###

  detection by 'ABSTRACT' header recognition - perhaps this is superfluous
  otherwise, should not assume next sequence after 'ABSTRACT' header is the abstract,
  as that is incorrect in some Elsevier. Checking for minimum length is a better
  way to pick the abstract with that Elsevier example.

  for sequence, s in sequences     
    token = skipDelimiters(tokens, sequence.startToken, sequence.endToken)
    if token?    
      if token.text.toUpperCase() is 'ABSTRACT'
        #logging.logRed 'abstract header found!!'
        if sequence.numOfTokens is 1
          #logging.logRed 'abstract header is part of sequence of length 1'
          if s < sequences.length-1 # if not last detected sequence, although should be impossible anyway
            #logging.logRed 'abstract header has section following it'
            abstract = sequences[s+1]
            logging.logYellow 'abstract detected via abstract title: ' + util.flattenSequenceText(tokens, abstract)
            break 
  ###

  #
  # otherwise, get abstract by the following criterion -
  # first 'long' sequence on first page
  #
  # bottom-wise first will be detected relying on the array having been sorted already
  #

  unless abstract?
    for sequence in sequences     
      if sequence.numOfTokens > minAbstractTokensNum 
        #console.dir sequence
        unless tokens[sequence.startToken].text?
          logging.logRed 'logical bug in abstract detection encountered for article; abstract may not be detected for this article'
        else
          if ctype.sentenceOpenerChar(tokens[sequence.startToken].text.charAt(0))
            unless UnplausiblyAbstract(tokens, sequence)
              abstract = sequence
              logging.logYellow ''
              logging.logYellow 'Article: ' + name
              logging.logYellow 'Detected abstract (non-final parsing):\n' + util.flattenSequenceText(tokens, abstract)
              logging.logYellow ''
              break

  if abstract?
    util.markTokens(tokens, abstract, 'abstract')
    #logging.logRed abstract.endToken - abstract.startToken
    #util.flattenSequenceText(tokens, abstract, 'abstract')
  else 
    console.warn 'abstract not detected'

  #
  # locate core article beginning, and mark any sequence to it's left as fluff
  #
  # for now, this will work only for articles 
  # where the core follows an 'Introduction' labeled header
  #
  for introduction in sequences     
    #console.log tokens[introduction.startToken].text
    if ((tokens[introduction.startToken].text is 'Introduction') or
        (tokens[introduction.startToken].text is '1.' and tokens[introduction.startToken+2].text is 'Introduction') or
        (tokens[introduction.startToken].text is '1'  and tokens[introduction.startToken+2].text is 'Introduction'))    
      console.log 'introduction detected'
      # remove fluff to the left of introduction section on the first page -
      # anything on the first page that is left (and not above) the introduction section
      for sequence in sequences     
        if parseFloat(sequence.startLeft) < parseFloat(introduction.startLeft)
          if parseFloat(sequence.startBottom) <= parseFloat(introduction.startBottom)
            # mark as fluff
            for t in [sequence.startToken..sequence.endToken]
              tokens

  if title?
    util.markTokens(tokens, title, 'title')  
    #util.flattenSequenceText(tokens, title, 'title')
  else 
    console.warn 'title not detected'

  #
  # Detect anything on the first page that is fluff
  #
  # assums that anything above the bottom of the abstract other than what's 
  # been already tagged and handled, is fluff. And anything left of the beginning
  # of the core text.
  #

  util.timelog(context, 'Title and abstract recognition')

  util.timelog(context, 'initial handling of first page fluff')

  if abstract?
    # Any sequence that starts higher than the abstract ends,
    # will be marked as fluff
    abstractEnd = tokens[abstract.endToken].positionInfo.bottom    # get bottom of abstract

    for sequence in sequences 
      unless (sequence is title or sequence is abstract)
        if parseFloat(tokens[sequence.startToken].positionInfo.bottom) > parseFloat(abstractEnd)  
          for t in [sequence.startToken..sequence.endToken]
            tokens[t].fluff = true

  util.timelog(context, 'initial handling of first page fluff')

#
# data-log a metaType
#
writeByMetaType = (context, tokens, type) ->
  text = ''
  for token in tokens
    if token.meta is type
      switch token.metaType 
        when 'regular'
          text += token.text + ' '

  if text.length > 0
    dataWriter.write context, type, text
    return true

  else
    console.warn """cannot data-write #{type} because no tokens are marked as #{type}"""
    return false
    
#
# Core of this module
#
generateFromHtml = (context, req, input, res ,docLogger, callback) ->  

  name = context.name

  util.timelog(context, 'Extraction from html stage A')

  xmlBuilder = xml.init # initialize output

  #
  # Read the input html 
  #

  rawHtml = fs.readFileSync(input.html).toString()
  
  #
  # Extract html css style info 
  #

  inputStylesMap = css.simpleFetchStyles(rawHtml, input.css) 

  htmlparser = require("htmlparser2");
  util.timelog(context, 'htmlparser2') 
  handler = new htmlparser.DomHandler((error, dom) ->
    if (error)
      docLogger.error('htmlparser2 failed loading document')
    else
      docLogger.info('htmlparser2 loaded document')
  )
  parser = new htmlparser.Parser(handler, {decodeEntities: true})
  parser.parseComplete(rawHtml)
  dom = handler.dom
  util.timelog context, 'htmlparser2'
 
  #
  # Build tokens while preserving the original css styles
  #

  nodesWithStyles = html.representNodes(dom)
  tokenArrays = (html.tokenize node for node in nodesWithStyles)

  # Flatten to one-dimensional array of tokens...
  tokens = []
  for tokenArray in tokenArrays
    for token in tokenArray
      tokens.push(token)

  if tokens.length == 0
    docLogger.error("No text was extracted from input")
    console.info("No text was extracted from input")
    error = 'We are sorry but the pdf you uploaded ' + '(' + name + ')' + ' cannot be processed. We are working on finding a better copy of the same article and will get back to you with it.' 
    callback(error, res, tokens, context, docLogger)
    return
    #throw("No text was extracted from input")

  # Smooth out styles such that each delimiter inherits the style of its preceding token. 
  # May belong either here or inside the core tokenization...
  tokens.reduce (x, y) -> 
    if y.metaType is 'delimiter' then y.stylesArray = x.stylesArray
    return y

  # TODO: duplicate to unit test
  for token in tokens when token.metaType is 'regular'
    if token.text.length == 0
      throw "Error - zero length text in data"

  #
  # Read the css style definitions of the css classes assigned to a token, 
  # and directly assign them to the token.
  #
  for token in tokens 
    token.finalStyles = {}
    token.positionInfo = {}

    for cssClasses in token.stylesArray  # cascade the styles from each parent node 
      for cssClass in cssClasses         # iterate over each css class indicated for the token,
                                         # adding its final style definitions to the token
        styles = css.getFinalStyles(cssClass, inputStylesMap)
        if styles? 
          for style in styles 
            if util.isAnyOf(style.property, css.positionData) # is position info? or is it real style?
              token.positionInfo[style.property] = style.value
            else
              token.finalStyles[style.property] = style.value
      
    if util.objectPropertiesCount(token.finalStyles) is 0
      docLogger.warn('No final styles applied to token')
      docLogger.warn(token)

  #
  # Unite tokens that do not have a delimiter in between them,
  # and are on the same line and of the same font.
  #
  # This is necessary for the cases where pdf2html splits parts of 
  # the same word between span elements. 
  #

  #
  # TODO:
  # There is an intricacy here. Sometimes, within a large normal document (e.g. MP0Zuz0FSSIenFyeHONS) there are
  # bits where there is a pair of attributes interacting in opposite directions around word continuity,
  # making word-continuity not deducable from the mere order of html spans.
  #
  # Those attributes are:
  # (a) letter-spacing and (b) a negative margin-left attribute. 
  #
  # computation evolving around those attributes directly applied to span elements and inherited, 
  # would probably be able to pick up word breaks for these cases.
  #

  util.timelog context, 'uniting split tokens'
  dataWriter.write context, 'stats', 'tokens count before uniting tokens: ' + tokens.length

  iterator(tokens, (a, b, index, tokens) -> 
    if a.metaType is 'regular' and b.metaType is 'regular'  # undelimited consecutive pair?
      if a.positionInfo.bottom is b.positionInfo.bottom     # on same row?
        if (a.finalStyles['font-size'] is b.finalStyles['font-size']) and
           (a.finalStyles['font-family'] is b.finalStyles['font-family']) # with same font?

          # Merge the two tokens 
          a.text = a.text.concat(b.text) 
          tokens.splice(index, 1)  # remove second element
          return 0
    return 1)  

  dataWriter.write context, 'stats', 'tokens count after uniting tokens:  ' + tokens.length
  util.timelog context, 'uniting split tokens'

  #
  # get an "aggregate token" that includes all properties in use
  # in the tokens, all in one token, to help model the token for a code refactor or Scala porting
  #
  if refactorMode
    refactorTools.deriveStructure(tokens)
    refactorTools.deriveStructureWithValues(tokens)

  if mode is 'bare'
    #
    # return the tokens to caller
    #
    callback(null, res, tokens, context, docLogger)
    return 

  #
  # From here down, logic that should preferably (?) move to Scala
  #

  #
  # Create page openers index
  #

  page = null
  pageOpeners = [util.first(tokens)]
  iterator(tokens, (a, b, i, tokens) ->
      if a.page isnt b.page
        pageOpeners.push(b)
      return 1
    )

  #
  # Detect repeat header and footer text
  # 

  util.timelog context, 'detect and mark repeat headers and footers'

  # Functional style setup
  GT  = (j, k) -> return j > k
  ST = (j, k) -> return j < k
  top    = { name: 'top', goalName: 'header', comparer: GT, extreme: 0}
  bottom = { name: 'bottom', goalName:'footer', comparer: ST, extreme: 100000}
  extremes = [top, bottom]

  for extreme in extremes

    # Get top-most and bottom-most page location across entire article
    for token in tokens
      position = parseInt(token.positionInfo.bottom)
      if extreme.comparer(position, extreme.extreme)
        extreme.extreme = position

    # Create an array of all sequences appearing at that top-most/bottom-most location

    extremeSequences = [] # Array of same row top-most/bottom-most elements 

    extremeSequence = []
    iterator(tokens, (a, b, i, tokens) ->
        if Math.abs(parseInt(a.positionInfo.bottom) - extreme.extreme) < 2  # grace variance
          extremeSequence.push(a)
          unless Math.abs(parseInt(b.positionInfo.bottom) - extreme.extreme) < 2 # same grace
            extremeSequences.push(extremeSequence)
            #consoleMsg = (token.text for token in extremeSequence)
            #console.log consoleMsg
            extremeSequence = []
        return 1 # go one position forward
      ) 

    #console.dir extremeSequences

    # Check that array for consecutive repeats, consecutively by a two page distance
    # because typically an article has repeat left-side headers/footers, 
    # and repeat right-hand headers/footers
    for physicalPageSide in [0..1] # Once for left-hand pages, and once for right-hand ones
      repeatSequence = 0
      for i in [physicalPageSide..extremeSequences.length-1-2] by 2
        a = extremeSequences[i]
        b = extremeSequences[i+2]

        # Is it a sequence repeating across two pages, at the top of them?
        repeat = true
        if a.length is b.length
          for t in [0..a.length-1]
            unless ((b[t].text is a[t].text) or (Math.abs(parseInt(b[t].text) - parseInt(a[t].text)) is 2)) # are they the same or one number apart?
              repeat = false
              
          # Mark the sequence as fluff in both 'consecutive' pages where it apperas
          if repeat 
            dataWriter.write context, 'partDetection', 'repeat header/footer:'
            for t in [0..a.length-1]
              a[t].fluff = true
              b[t].fluff = true
              #console.log a[t].text
            repeatSequence +=1
          
      #console.log repeatSequence
      unless repeatSequence > 0 
        logging.cond 'no repeat ' + extreme.goalName + ' ' + 'detected in article' + ' ' + 'in pass' + ' for ' + (if physicalPageSide is 0 then 'even pages' else 'odd pages'),
                     'partDetection'
      else 
        logging.cond repeatSequence + ' ' + 'repeat' + ' '+ extreme.goalName + 's' + ' ' + 'detected in article' + ' ' + 'in pass' + ' ' +  (if physicalPageSide is 0 then 'even pages' else 'odd pages'),
                     'partDetection'

  #
  # Remove first page number footer even if it does not appear consistently  
  # the same as in later pages repeat footers
  #
  # TODO: consider grouping with elaborate fluff removal when implemented
  #

  dataWriter.write context, 'partDetection', 'bottom extreme is ' + bottom.extreme
  for token in tokens when parseInt(token.page) is 1
    if Math.abs(parseInt(token.positionInfo.bottom) - bottom.extreme) < 2 # same grace      
      dataWriter.write context, 'partDetection', '1st page non-repeat footer text detected: ' + token.text
      token.fluff = true
  
  util.timelog context, 'detect and mark repeat headers and footers'

  #
  #
  #

  titleAndAbstract(context, tokens)
 
  #
  # Now effectively remove all identified fluff the identified repeat sequences
  #

  filtered = []
  for t in [0..tokens.length-1]
    unless tokens[t].fluff?
      filtered.push(tokens[t])
    else
      #console.log """filtered out token text: #{tokens[t].text}"""
  tokens = filtered
  
  #
  # Detect row endings and beginnings
  # and generally handle implications of row beginnings.
  #
  # This function may have few logical holes in it:
  #
  # TODO: parameterize direction to support RTL languages
  # TODO: this code assumes positions are given in .left and .bottom not .right and .top or other
  # TODO: this code compares position on an integer rounding basis, this is only usually correct
  # TODO: this code assumes the size unit is px and some more 
  #

  #
  # handle title and abstract, and core text beginning detection
  # this also marks out most first page fluff
  #
  util.timelog context, 'basic handle line and paragraph beginnings'

  ###
  util.timelog 'making copy'
  tokens = JSON.parse(JSON.stringify(tokens))
  util.timelog 'making copy'
  ###

  #
  # Mark line openers and closers, 
  # as well as column openers and closers
  #

  lineOpeners = []
  lineOpenersForStats = []
  lineSpaces = []

  util.first(tokens).lineOpener = true

  for i in [1..tokens.length-1]
    a = tokens[i-1]
    b = tokens[i]
    
    # Identify and handle new text column, and thus identify a new line
    if parseFloat(b.positionInfo.bottom) > parseFloat(a.positionInfo.bottom) + 100
      a.lineCloser = true       # a line closer       
      b.lineOpener = true       # a line opener 
      a.columnCloser = true           # a column closer
      b.columnOpener = true           # a column opener
      lineOpeners.push(i)  # pushes the index of b
      lineOpenersForStats.push parseFloat(b.positionInfo.left)

    # Identify and handle a new line within same column
    else
      if parseFloat(b.positionInfo.bottom) + 5 < parseFloat(a.positionInfo.bottom) 
        a.lineCloser = true       # a line closer       
        b.lineOpener = true       # a line opener       
        lineOpeners.push(i)  # pushes the index of b
        lineOpenersForStats.push parseFloat(b.positionInfo.left)
        lineSpaces.push parseFloat(a.positionInfo.bottom) - parseFloat(b.positionInfo.bottom) 

    if b.lineOpener
      if b.text is 'References' then logging.logGreen """References line opener has indentation change and preceded by #{a.text}"""

  lineSpaceDistribution = analytic.generateDistribution(lineSpaces)
  
  #for entry in lineSpaceDistribution
  #console.log """line space of #{entry.key} - detected #{entry.val} times"""

  newLineThreshold = parseFloat(util.first(lineSpaceDistribution).key) + 1  # arbitrary grace interval to absorb
                                                                            # floating point calculation deviations 
                                                                            # and document deviations 
  dataWriter.write context, 'stats', """ordinary new line space set to the document's most common line space of #{newLineThreshold}"""

  util.last(tokens).lineCloser = true

  #
  # Based on the above, deduce paragraph splittings
  #

  for i in [1..lineOpeners.length-1-1] 

    currOpener = tokens[lineOpeners[i]]   # current row opener
    prevOpener = tokens[lineOpeners[i-1]] # previous row opener  
    nextOpener = tokens[lineOpeners[i+1]] # previous row opener  
    prevToken  = tokens[lineOpeners[i]-1] # token immediately preceding current row opener

    # if currOpener.text is 'References' then logging.logYellow "REFERENCES"
    
    # skip new paragraph recognition within the article title -
    # as titles tend to span few lines while being center justified,
    # the paragraph splitting test should be avoided within them
    if currOpener.meta is 'title' 
      continue 

    # is there an indentation change?
    if parseInt(currOpener.positionInfo.left) > parseInt(prevOpener.positionInfo.left)
      if currOpener.text is 'References' then logging.logYellow """References line opener has indentation change and preceded by #{prevToken.text}. Metatypes are: #{currOpener.metaType}, #{prevToken.metaType}"""

      # is it a column transition?
      if currOpener.columnOpener
        if parseInt(currOpener.positionInfo.left) > parseInt(nextOpener.positionInfo.left)
          # it's a paragraph beginning at the very top of a new column
          currOpener.paragraphOpener = true
          prevToken.paragraphCloser = true
          #console.log 'new paragraph detected by rule 1:' + currOpener.text

      else
        if currOpener.text is 'References' then logging.logYellow "is paragraph opener"
        # it's a paragraph beginning within the same column
        currOpener.paragraphOpener = true  
        prevToken.paragraphCloser = true
        #console.log 'new paragraph detected by rule 2:' + currOpener.text        

    if parseFloat(currOpener.positionInfo.bottom) + newLineThreshold < parseFloat(prevOpener.positionInfo.bottom) - 1  # -1 for tolerance 
      # it's a space signaled paragraph beginning
      currOpener.paragraphOpener = true   
      prevToken.paragraphCloser = true
      #console.log 'new paragraph detected by rule 3:' + currOpener.text        
     
      #console.log newLineThreshold + ' ' + parseFloat(currOpener.positionInfo.bottom) + ' ' + parseFloat(prevOpener.positionInfo.bottom) 
      #console.log parseFloat(currOpener.positionInfo.bottom) + newLineThreshold - parseFloat(prevOpener.positionInfo.bottom) 
      #console.log prevOpener.text + ' ' + currOpener.text

      #console.log """detected space delimited paragraph beginning: #{currOpener.text}"""

  util.timelog context, 'basic handle line and paragraph beginnings'

  #
  # Derive paragraph length and quantity statistics - should probably be moved
  #

  lastOpenerIndex = 0
  paragraphs = []
  for i in [0..tokens.length-1] 
    if tokens[i].paragraphOpener
      paragraphs.push {'length': i - lastOpenerIndex, 'opener': tokens[i]}
      lastOpenerIndex = i

  dataWriter.write context, 'stats', """detected #{paragraphs.length} paragraphs"""
  #paragraphs.sort( (a, b) -> return parseInt(b.length) - parseInt(a.length) )
  
  #for paragraph in paragraphs
  #  console.log """beginning in page #{paragraph.opener.page}: paragraph of length #{paragraph.length}"""

  dataWriter.write context, 'stats', """number of pages in input document: #{parseInt(util.last(tokens).page)}"""
  paragraphsRatio = paragraphs.length / parseInt(util.last(tokens).page)

  averageParagraphLength = analytic.average(paragraphs, (a) -> a.length)
  
  dataWriter.write context, 'stats', """paragraphs to pages ratio: #{paragraphsRatio}"""
  dataWriter.write context, 'stats', """average paragraph length:  #{averageParagraphLength}"""

  lineOpenersDistribution = analytic.generateDistribution(lineOpenersForStats)
  for entry in lineOpenersDistribution
    logging.cond """line beginnings on left position #{entry.key} - detected #{entry.val} times""", 'basicParse'

  ###
  paragraphLengthsDistribution = analytic.generateDistribution(paragraphLengths)
  for entry in paragraphLengthsDistribution
   console.log """paragraph length of #{entry.key} tokens - detected #{entry.val} times"""
  ###

  #
  # Identify and handle superscript 
  #
  # while adding a delimiter so that the superscript token doesn't get combined with 
  # the token preceding it, thus losing its superscript property in the curernt algorithm
  # This can later be refined e.g. to reflect this is not a regular space delimiter,
  # as well as enable propagating the relative font size and height of the super/subscript, 
  # or otherwise
  #
  # TODO: this may possibly move to the basic tokenization
  #       rather than be handled here 'in retrospect', or be extended
  #       to handling other formatting variances (?) not just superscript
  #

  addStyleSeparationDelimiter = (i, tokens) ->

    a = tokens[i]

    newDelimiter = {'metaType': 'delimiter'}
    newDelimiter.styles = a.styles
    newDelimiter.finalStyles = a.finalStyles    
    newDelimiter.page = a.page
    newDelimiter.meta = a.meta
    tokens.splice(i, 0, newDelimiter) # add a delimiter in this case

  tokens.reduce (a, b, i, tokens) ->        

    unless a.lineCloser
      switch
        when parseInt(b.positionInfo.bottom) > parseInt(a.positionInfo.bottom)
            b.superscript = true  
            addStyleSeparationDelimiter(i, tokens)
        when parseInt(b.positionInfo.bottom) < parseInt(a.positionInfo.bottom)
            a.superscript = true  
            addStyleSeparationDelimiter(i, tokens)

    return b

  #
  # Handle end-of-line tokenization aspects to complete the delimitation of the token sequence:
  # 1. Add a delimiter if end of line didn't already include one
  # 2. Uniting hyphen-split words (E.g. 'associa-', 'ted' -> 'associated') split at the end of a line
  #

#  for token, t in tokens
#    if token.text is 'References' then logging.logYellow """References is #{token.paragraph} and #{tokens[t-1].text} is #{tokens[t-1].paragraph} """

  #for token in tokens
  #  if token.text is 'run.' then logging.logYellow "run still here"
  #  if token.text is 'References' then logging.logYellow "Referencse still here"

  docLogger.info(tokens.length)
  iterator(tokens, (a, b, i, tokens) ->                             
    if b.lineOpener
      if a.lineCloser
        #if b.text is 'References' then logging.logYellow "@References"
        if a.metaType is 'regular' # line didn't include an ending delimiter 
          #docLogger.info('undelimited end of line detected')
          # if detected, unite a line boundary 'hypen-split'
          if util.endsWith(a.text, '-')
            a.text = a.text.slice(0, -1)   # discard the hyphen
            a.text = a.text.concat(b.text) # concatenate text of second element into first
            #b.metaType is 'virtual'        # okay, this is a hack. we need this 
                                            # so we maintain information about the line opening geometry
                                            # (left position at least), but this is hackish as it mixes
                                            # the content model with the geometric model too much
            tokens.splice(i, 1)           # remove second element
            return 0
  
          # add a delimiter at the end of the line, unless a hyphen-split 
          # was just united, in which case it's not necessary
          else
            if a.text is 'run.' then logging.logYellow "not Hyphen"
            newDelimiter = {'metaType': 'delimiter'}
            newDelimiter.styles = a.styles
            newDelimiter.finalStyles = a.finalStyles 
            newDelimiter.page = a.page   
            newDelimiter.meta = a.meta
            tokens.splice(i, 0, newDelimiter) # add a delimiter in this case
            return 2
    return 1)

  #
  # Unite tokens that do not have a delimiter in between them.
  # This is necessary for the cases where pdf2html splits parts of 
  # the same word between span elements. 
  #
  # Moved higher up in the pipeline, can probably be removed from here
  # as duplication
  #

  iterator(tokens, (a, b, index, tokens) -> 
    if a.metaType is 'regular' and b.metaType is 'regular'

      # Merge the two tokens - styles from first, paragraph status from second
      a.text = a.text.concat(b.text) # concatenate text of second element into first
      a.paragraphOpener = b.paragraphOpener
      a.paragraphCloser = b.paragraphCloser

      tokens.splice(index, 1)        # remove second element
      return 0
    return 1)

  for token in tokens
    if token.text is 'run.References' then logging.logYellow "run. and References were united now"

  #docLogger.info(tokens.length)

  util.timelog context, 'Extraction from html stage A'

  #
  # Add a running sequence id to the tokens (after all uniting of tokens already took place)
  #

  util.timelog context, 'ID seeding'
  id = 0
  for token in tokens
    token.id = id
    id += 1
  util.timelog context, 'ID seeding'

  if createIndex
    #
    # Create a sorted index - mapping from each word to the locations where it appears
    #
    textIndex = []
    for token in tokens when token.metaType is 'regular'
      textIndex.push({text: token.text, id: token.id})
    util.timelog(context, 'Index creation')    
    textIndex.sort((a, b) ->  # simple sort by lexicographic order obliviously of the case of equality
      if a.text > b.text
        return 1
      else
        return -1)
    util.timelog context, 'Index creation'      
    #docLogger.info textIndex

  #
  # Enrich tokens with computed style meta-data.
  # For now one enrichment type - capitalization type
  #

  

  for token in tokens
    if token.metaType is 'regular'
      
      token.case = 'undetermined'

      if ctype.testWeakUpperCase(token.text)
        token.case = 'upper'
        #dataWriter.write context, 'partDetection', 'All Caps Style detected for word: ' + token.text
      if ctype.isUpperCaseChar(token.text.charAt(0)) 
        token.case = 'title'
  
      # TODO: interleave this check much much earlier on in the tokenization stage
      # if util.pushIfTrue(token.calculatedProperties, ctype.testInterspacedTitleWord(token.text))
      #   dataWriter.write context, 'partDetection', 'Interspaced Title Word detected for word: ' + token.text
  
  # mix in header indications into token sequence
  headers(context, tokens)

  #
  # Create sentences sequence
  # Temporary note: For now, each sentence will be tokenized to have its tokens become an array
  #                 inside the groups array. Later, there can be more types of groups etc..
  #

  util.timelog(context, 'Sentence tokenizing')
  connect_token_group = ({group, token}) ->   # using named arguments here..
    group.push(token)
    #token.partOf = group      

  abbreviations = 0
  groups = [] # sequence of all groups
  group = []  
  for token,t in tokens when token.meta isnt 'header'
    if token.metaType is 'regular' 
      connect_token_group({group:group, token:token})
      if sentenceSplitter.endOfSentence(tokens, t) # Is this a sentence ending?
        groups.push(group) # close off a 'sentence' group
        group = []
  unless group.length is 0  # Close off trailing bits of text if any, 
    groups.push(group)      # as a group, whatever they are. For now.

  util.timelog context, 'Sentence tokenizing'  

  #
  # output title and abstract 
  #
  xmlBuilder += xml.signal('abstract', 'opener')
  for token in tokens when token.meta is 'abstract'
    if token.metaType is 'regular' then xmlBuilder += xml.escape(token.text)
    else xmlBuilder += ' '

  xmlBuilder += xml.signal('abstract', 'closer')

  # data-log abstract, title
  writeByMetaType(context, tokens, 'abstract')
  writeByMetaType(context, tokens, 'title')

  #
  # output all sentences, with paragraph splits and with sections derived by headers
  #
  sentences = []
  inSection = false
  xmlBuilder += xml.signal('body', 'opener')

  for group in groups
    sentence = ''
    for token in group

      # mark section edges in xml
      if token.sectionOpener
        logging.logRed 'section opener'
        if inSection 
          xmlBuilder += xml.signal('paragraph', 'closer') # This does not really rely on paragraph detection, just arbitrary
          xmlBuilder += xml.signal('section', 'closer')
        xmlBuilder += xml.signal('section', 'opener', {sectionType: token.sectionType, sectionName: token.sectionOpenerName})
        xmlBuilder += xml.signal('paragraph', 'opener')   # This does not really rely on paragraph detection, just arbitrary
        inSection = true

      # mark paragraph edges in xml
      #if token.paragraphOpener then xmlBuilder += xml.signal('paragraph', 'closer') + xml.signal('paragraph', 'opener') 
      #if token.paragraphCloser then xmlBuilder += xml.signal('paragraph', 'closer')      

      if token.meta in ['title', 'abstract']
        continue

      sentence += token.text + ' '

    if sentence.length is 0
      continue

    sentences.push sentence
    xmlBuilder += xml.escape(sentence)
    
  if inSection
    xmlBuilder += xml.signal('paragraph', 'closer') # This does not really rely on paragraph detection, just arbitrary
    xmlBuilder += xml.signal('section', 'closer') # close off last section if any
    inSection = false
  xmlBuilder += xml.signal('body', 'closer')

  xmlBuilder = xml.wrapAsJatsArticle(xmlBuilder)

  #
  # write out key results for downstream semantic engine
  #
  dataWriter.writeArray context, 'sentences', sentences
  
  #
  # write these out synchronously, so http consumer can act on them once it got its http response
  #
  # a finer flow scheme would not block but rathar group all write callbacks of a batch
  # invocation, and allow an http response once they all finished, or provide
  # notification per processed article (see async callback here http://nodejs.org/api/fs.html#fs_fs_writefile_filename_data_options_callback)
  #
  fs.writeFileSync(JATSoutPath + context.name + '.xml', xmlBuilder) #, doner(err))
  fs.writeFileSync(TextoutPath + '/' + context.name, sentences.join('\n'))
  logging.logYellow 'written as text and as JATS'

  if mode is 'basic'
    #
    # return the tokens to caller
    #
    callback(null, res, tokens, context, docLogger)

    return 

  # Log some statistics about sentences
  documentQuantifiers = {}
  documentQuantifiers['sentences']                    = groups.length
  documentQuantifiers['period-trailed-abbreviations'] = abbreviations
  console.dir(documentQuantifiers)

  #
  # Adding marker highlighting - this is now disabled, and implementation
  # should consider a different programming language
  #

  util.timelog(context, 'Markers visualization') 

  docSieve = markers.createDocumentSieve(markers.baseSieve) # Derives the markers sieve for use for this document
  #util.logObject(docSieve)  
  
  #
  # This bit will be moved to a CPU efficient language
  #
  # Rather than a loop (formerly: for sentence in groups),
  # iterate the sentences such that each sentence queues handling 
  # of the next one on the call stack. So that this cpu intensive bit doesn't block the process
  #
  # This needs to become Scala / Clojure or quicker language if it's the main bottleneck,
  # or just a separate node.js process receiving requests from here...
  # logging should be as unified as possible in any event.
  #
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
                if marker.nextExpected is (marker.markerTokens.length - 1) # is it the last token of the marker?
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
        util.timelog context, 'Markers visualization'

        # Done. Send back response, after attaching the result data to the session
        #req.session.tokens = require('circular-json').stringify(tokens) # takes 100 times longer than JSON.stringify so can't afford it
        
        #req.session.tokensPickled = JSON.stringify(tokens)
        #console.log req.session.tokens
        #outputHtml = html.buildOutputHtml(tokens, inputStylesMap, docLogger)        
        req.session.tokens = tokens
        callback()

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
  
  # TODO: duplicate to unit test
  for token in tokens
    unless token.page? 
      throw "Internal Error - token is missing page number"

  #
  # get an "aggregate token" that includes all properties in use
  # in the tokens, all in one token, to help model the token.
  #
  deriveStructure(tokens)
  deriveStructureWithValues(tokens)

  if mode is 'all'
    #
    # return the tokens to caller
    #
    callback(null, res, tokens, context, docLogger)
    return 


exports.generateFromHtml = generateFromHtml

#
# send the output, 
# terminate resources used for handling the input file
# 
done = (error, res, tokens, context, docLogger) -> 

  name = context.name

  # close dataWriters to avoid file descriptor leak
  shutdown = () ->
    util.closeDocLogger(docLogger)
    dataWriter.close(name)

    compare = require '../compare/compare'
    
    unless context.runID.indexOf('self-test-on-startup') >= 0
      setTimeout((() -> 
          compare.diff(context, 'sentences')
          compare.diff(context, 'headers')), 
        3000)

  if error?
    res.writeHead 505
    res.write error
    res.end()
    shutdown()
    return

  sendTokens = () ->
    chunkResponse = true

    chunkRespond = (payload, res) ->
      sentSize = 0
      maxChunkSize = 65536 # 2^16
      for i in [0..payload.length / maxChunkSize]
        chunk = payload.substring(i*maxChunkSize, Math.min((i+1)*maxChunkSize, payload.length))
        logging.cond """sending chunk of length #{chunk.length}""", 'communication'
        sentSize += chunk.length
        res.write(chunk)
      res.end()
      assert.equal(sentSize, payload.length, "payload chunking did not send entire payload")

    if tokens? 
      if tokens.length>0
        util.timelog context, 'pickling'
        serializedTokens = JSON.stringify(tokens)
        dataWriter.write context, 'stats', """#{tokens.length} tokens pickled into #{serializedTokens.length} long bytes stream"""
        dataWriter.write context, 'stats',  """pickled size to tokens ratio: #{parseFloat(serializedTokens.length)/tokens.length}"""
        util.timelog context, 'pickling'

        if chunkResponse
          chunkRespond(serializedTokens, res)
        else
          res.end(serializedTokens)

        shutdown()
        return

    else
      res.send(500)  
      shutdown()

  # only shutdown, do not reply with tokens for now, as they go through a file anyway
  shutdown()
  res.end("""Done processing #{context.name}. See output in output folders #{JATSoutPath}, #{TextoutPath}""")

exports.go = (context, req, input, res ,docLogger) ->
  name = context.name

  logging.cond "about to generate tokens", 'progress'
  generateFromHtml(context, req, input, res ,docLogger, done) 
  
#
# original version, of exports.go - not in use
#
exports.originalGo = (req, name, res ,docLogger) ->
 
  storage = require '../src/storage/simple/storage'
  require 'stream'
  #riak = require('riak-js').getClient({host: "localhost", port: "8098"})

  util.timelog context, 'checking data store for cached tokens'
  
  storage.fetch('tokens', name, (cachedSerializedTokens) -> 
    util.timelog context, 'checking data store for cached tokens'
    if cachedSerializedTokens
      # serve cached tokens
      console.log 'cached tokens found in datastore'
      req.session.serializedTokens = cachedSerializedTokens      
      output.serveViewerTemplate(res, docLogger)
    else
      # not cached - perform the extraction
      console.log 'no cached tokens found in datastore'
      generateFromHtml(req, name, res ,docLogger, () -> output.serveViewerTemplate(res, docLogger)) 
  )
