util  = require '../util/util'
ctype = require '../util/ctype'
specialCaseWords = [ 'vs.', 'al.', 'cf.', 'st.' ,'Fig.', 'FIG.']

# return wether current token is a period delimited acronym - e.g. "U.S.", "E.G.".
acronym = (string) ->
  firstIndex = string.indexOf('.')
  if firstIndex is -1 
    return false

  if firstIndex < string.length - 1
    return true

  return false      

#
# Return whether current token may indicate an end of a sentence.
#
exports.endOfSentence = (tokens, t) ->

  string = tokens[t].text

  length = string.length
  
  if string.charAt(length-1) in ['?', '!']
    return true

  if string.charAt(length-1) is '.'
    # if not a special case, it may be an end of a sentence marked by a period char
    for match in specialCaseWords 
      if util.endsWith(string, match)
        return false # it's a special case, not an end of a sentence

    # decide for the special case of a period delimited acronym,
    # in which case we need some help from the next token as well (http://english.stackexchange.com/questions/711/punctuation-around-abbreviations)
    if acronym(string)
      
      # is it followed by a token starting with an upper case?
      if t + 2 < tokens.length
        if tokens[t+1].metaType is 'delimiter'
          if tokens[t+2].metaType is 'regular'
            nextString = tokens[t+2].text
            if ctype.isUpperCaseChar(nextString.charAt(0))
              return true

      return false # if none of the cases, then it's not an end of a sentence

    return true # no special case words detected     
  
  return false
   