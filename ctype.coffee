util    = require './util'
logging = require './logging' 

#
# Checks if a character is an alphabetic character
# 'Alphabetic' means that it's a letter, not a number,
# punctuation, symbol, etc...
#
# Note: should work for vast majority of unicode covered alphabets - except
# Turkish or few more - (as noted in http://goo.gl/Ol5X8I, mozilla documentation).
#
isAlphabetChar = (char) ->
  char.toUpperCase() isnt char.toLowerCase()  # The simplest javascript way....

exports.isAlphabetChar = isAlphabetChar

isLowerCaseChar = (char) ->
  char is char.toLowerCase()

exports.isLowerCaseChar = isLowerCaseChar

isUpperCaseChar = (char) -> not isLowerCaseChar(char)

#
# Checks if a string is a purely alphabetic uppercase sequence.
# 'purely alphabetic' means it's pure alphabet letters, no numbers, symbols, punctutaion...
#
# Note: Heuristically assumes no string of 3 characters or less would be styled this way. 
#
exports.testPureUpperCase = (string) -> 
  if string.length < 3 then return false 
  for char in string.split ''       # one strike and we're out.....
    if not isAlphabetChar(char)     # is it not an alphabet char?
      return false
    if isLowerCaseChar(char)         # is it not uppercase?
      return false  

  return true
    
#
# Checks if a string is a weakly alphabetically uppercase sequence
# 'weakly alphabetic' means wherever it has alphabet in it, it is upper case.
# Should work for vast majority of unicode covered alphabets - except
# Turkish or few more - (as noted in http://goo.gl/Ol5X8I, mozilla documentation).
#
# Note: Heuristically assumes no string of 3 characters or less would be styled this way. 
#
exports.testWeakUpperCase = (string) -> 
  if string.length < 3 then return false 
  for char in string.split ''       # one strike and we're out.....
    if isAlphabetChar(char)         # ignore non-alphabetic chars
      if isLowerCaseChar(char)       # is it not uppercase?
        return false  

  return true

#
# Check if a string is something like "a b s t r a c t"
# Heuristically assume no string of 3 characters or less would be styled this way. 
# Note: this is very sketchy, not sure how much this will be really needed.
# TODO: extend this to recognize a word sequence that is stylef this way, etc., if helpful.
# TODO: refactor to make a sequence like "a b s t r a c t" not break into 8 words,
#       so that it can be captured by a function like this or other
# 
exports.testInterspacedTitleWord = (string) ->
  if string.length < 4 then return false  
  for i in [0..string.length/2] by 2
    unless (isAlphabetChar(string.charAt(i)) and string.charAt(i+1) is util.anySpaceChar)
      return false

  return true      
