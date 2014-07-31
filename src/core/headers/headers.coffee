#
# Helper function for iterating token pairs
#

dataWriter = require '../../data/dataWriter'

expected   = require './expected'

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

module.exports = (name, tokens) -> 

  console.dir expected

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

      dataWriter.write name, 'headers', """token id #{curr.id}: #{curr.text}"""
    )



