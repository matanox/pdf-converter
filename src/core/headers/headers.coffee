#
# Helper function for iterating token pairs
#

dataWriter = require '../../data/dataWriter'
logging    = require '../../util/logging' 

expected   = require './expected'

noHeadersDocs = 0

#
# Iterate the tokens array, having the previous, current and next item available to each pass
# 
tripleIterator = (tokens, func) ->
  
  i = 1
  while i < tokens.length - 1
    prev = tokens[i-1]
    curr = tokens[i]
    next = tokens[i+1]
    func(prev, curr, next) 

    i = i + 1

#
# is the token distinct in font family, size, compared to its immediate environment?
#
separateness = (first, second) ->
  #logging.logBlue "separateness test"
  #logging.logBlue """size: #{curr.finalStyles['font-size']} font: #{curr.finalStyles['font-family']} v.s. 
  #                     size: #{prev.finalStyles['font-size']} font: #{prev.finalStyles['font-family']} """

  if first.finalStyles['font-size'] isnt second.finalStyles['font-size']
    return true
  if first.finalStyles['font-family'] isnt second.finalStyles['font-family']
    return true

  return false

sameness = (first, second) -> not separateness(first, second)
styleContinuity = sameness

#
# return index of last token in style-continuous sequence starting at index t
#
getContinuouslyStyled = (tokens,t) ->
  while t + 1 < tokens.length and styleContinuity(tokens[t], tokens[t+1])
    ender = t+1
    t += 1
  return ender

#
# returns true if token exists and fulfills condition
#
test = (tokens, t, f) -> t < tokens.length and f(tokens[t])
  
#
# tests next non-delimiter if any
#
testNext = (tokens, t, f) ->

  if test(tokens, t+1, (token) -> token.metaType is 'delimiter')
    if test(tokens, t+2, (token) -> token.metaType is 'regular')
      if f(tokens[t+2])
        return true

  return false

#
# tests if has a next non-delimiter
#
hasNext = (tokens, t, f) ->
  if test(tokens, t+1, (token) -> token.metaType is 'delimiter')
    if test(tokens, t+2, (token) -> token.metaType is 'regular')
      return true

  return false

optionallyCasedInTitle = ['and', 'for', 'in', 'of', 'the']

isTitlishCase = (token) -> 
  token.case in ['upper', 'title'] or not isNaN(parseFloat(token.text)) or token.text in optionallyCasedInTitle

isTitlishCaseSequence = (tokens, start, end) ->
  for t in [start..end]
    if tokens[t].metaType is 'regular' and not isTitlishCase(tokens[t]) 
      return false

  return true

startsWithDigit = (text) ->
        ([1..9].some((i) -> parseInt(text.charAt(0)) == i)) # does it start with a digit between 1 and 9 ?

#
# check if text contains any of a list of expected header words
#
hasExpectedsequence = (text) ->
  found = false
  for e in expected
    if text.indexOf(e) > -1
      found = true
  return found

#
# TODO: catch all headers not just those easy to catch.
#       that would require a refactor of this function and likely some recursion.
#
module.exports = (context, tokens) -> 

  getLevelStyle = (token) -> 
    levelStyle = 
      finalStyles:
        "font-size":   token.finalStyles['font-size'], 
        "font-family": token.finalStyles['font-family']

  anyFound = false
  headers = [] # not used

  # work with just the regular (non-delimiter) tokens
  regularTokens = tokens.filter((token) -> return token.metaType is 'regular')

  for token, t in tokens
    if t < tokens.length
      prev = tokens[t-1]
  
    ###
    if token.text? and token.text is 'References'
      console.dir tokens[t-1]
      logging.logBlue "References token:"
      console.dir token
    ###

    # catch header not starting with numeral
    if token.paragraphOpener
      unless separateness(prev, token) then continue # require style change
      
      sequenceAsText = ''
      seqEnd = getContinuouslyStyled(tokens, t)
      for h in [t..seqEnd] 
        sequenceAsText += if tokens[h].metaType is 'regular' then tokens[h].text else ' '

      unless isTitlishCaseSequence(tokens, t, seqEnd) then continue # require titlish case

      if sequenceAsText.indexOf("Introduction") > -1
        logging.logBlue 'level1 style captured'
        level1Style = getLevelStyle(token)

      unless hasExpectedsequence(sequenceAsText) or 
             (level1Style? and sameness(token, level1Style)) then continue # require partial match to expected headers list          

      detectionComments = []
      if hasExpectedsequence(sequenceAsText) then detectionComments.push 'expected header text'
      if (level1Style? and sameness(token, level1Style)) then detectionComments.push 'mirrors introduction header style'

      # getting here, declare this a beginning of a header 
      anyFound = true
      dataWriter.write context, 'headers', { 
          tokenId: token.id, 
          header:  sequenceAsText, 
          level:   1
          detectionComment: detectionComments.join " & "
        }

      logging.logBlue "detected header - " + detectionComments.join(" & ") + ": " + sequenceAsText

  # console logging to help with single file run
  unless anyFound
    noHeadersDocs += 1
    logging.logRed """no headers detected for #{context.name} (#{noHeadersDocs} total)"""



