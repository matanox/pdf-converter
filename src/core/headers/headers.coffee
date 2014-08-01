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

isTitleNumeral = (text) ->
  if not isNaN(parseInt(text.charAt(0))) # is first char a digit?
    return true

  return false

#
# is the token distinct in font family, size, compared to its immediate environment?
#
separateness = (prev, curr) ->
  logging.logYellow "separateness test"
  logging.logYellow """size: #{curr.finalStyles['font-size']} font: #{curr.finalStyles['font-family']} v.s. 
                       size: #{prev.finalStyles['font-size']} font: #{prev.finalStyles['font-family']} """

  if curr.finalStyles['font-size'] isnt prev.finalStyles['font-size']
    return true
  if curr.finalStyles['font-family'] isnt prev.finalStyles['font-family']
    return true


  return false


module.exports = (name, tokens) -> 

  #console.dir expected

  anyFound = false

  headers = []

  # work with just the regular (non-delimiter) tokens
  regularTokens = tokens.filter((token) -> return token.metaType is 'regular')

  tripleIterator(regularTokens, (prev, curr, next) ->
      # check if token is one of the expected header level 1 list
      if expected.indexOf(curr.text) is -1
        return
   
      # check if token has a case implying possibly being a title
      unless curr.case in ['upper', 'title']   
        return

      if curr.paragraph is 'opener'
        if separateness(prev, curr)
          anyFound = true
          dataWriter.write name, 'headers', """token id #{curr.id}: #{curr.text} (paragraph opener)""", true
          return

      if isTitleNumeral(prev.text)
        logging.logRed prev.paragraph
        if prev.paragraph is 'opener'      
          anyFound = true
          dataWriter.write name, 'headers', """token id #{curr.id}: #{curr.text} (following numeral paragraph opener)""", true
          return
    )

  unless anyFound
    logging.logRed """no headers detected for #{name} (#{noHeadersDocs} total)"""
    noHeadersDocs += 1



