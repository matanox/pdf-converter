# crepl = require 'coffee-script/lib/coffee-script/repl'

endsWith = (string, match) ->
  string.lastIndexOf(match) is string.length - match.length

exports.endWith = endsWith

startsWith = (string, match) ->
  string.indexOf(match) is 0

exports.startsWith = startsWith

contains = (string, match) ->
  string.indexOf(match) isnt -1

#
# Strip a string from a given header and trailer, if they indeed are.
#
exports.strip = (string, prefix, suffix) ->
  if !startsWith(string, prefix)
    throw("Cannot strip string of the supplied prefix")
  if !endsWith(string, suffix)
    throw("Cannot strip string of the supplied suffix")

  string.slice(string.indexOf(prefix)+prefix.length, string.lastIndexOf(suffix))      

# Utilty function for checking if a string matches any of a given set of strings.
# Regex building could be an alternative implementation...
isAnyOf = (string, matches) ->
  matches.some((elem) -> elem.localeCompare(string, 'en-US') == 0)

exports.isAnyOf = isAnyOf

exports.endsWithAnyOf = (string, matches) ->
  trailingChar = string.charAt(string.length - 1)
  return false unless isAnyOf(trailingChar, matches)
  return trailingChar

exports.startsWithAnyOf = (string, matches) ->
  char = string.charAt(0)
  return false unless isAnyOf(char, matches)
  return char

exports.parseElementText = (xmlNode) ->
  content = xmlNode.substr(0, xmlNode.length - "</div>".length) # remove closing div tag
  content = content.slice(content.indexOf(">") + 1)             # remove opening div tag
  content

#exports.arrayToMap = (array) ->
  #map[obj[key]] = element for element in array 

exports.logObject = (obj) -> console.log(JSON.stringify obj, null, 2) 

exports.objectViolation = (errorMessage) ->
  error = new Error(errorMessage)
  console.log(error.stack)
  throw error   