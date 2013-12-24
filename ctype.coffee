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

#
# Checks if a string is a purely alphabetic uppercase sequence.
# 'purely alphabetic' means it's pure alphabet letters, no numbers, symbols, punctutaion...
#
exports.testPureUpperCase = (string) -> 
  for char in string.split ''       # one strike and we're out.....
    if not isAlphabetChar(char)     # is it not an alphabet char?
      return false
    if isAlphabetChar(char)         # is it not uppercase?
      return false  

  return true
    
#
# Checks if a string is a weakly alphabetically uppercase sequence
# 'weakly alphabetic' means wherever it has alphabet in it, it is upper case.
# Should work for vast majority of unicode covered alphabets - except
# Turkish or few more - (as noted in http://goo.gl/Ol5X8I, mozilla documentation).
#
exports.testWeakUpperCase = (string) -> 
  for char in string.split ''       # one strike and we're out.....
    if isAlphabetChar(char)         # ignore non-alphabetic chars
      if isAlphabetChar(char)       # is it not uppercase?
        return false  

  return true
