# crepl = require 'coffee-script/lib/coffee-script/repl'

endsWith = (string, match) ->
  string.lastIndexOf(match) is string.length - match.length

startsWith = (string, match) ->
  string.indexOf(match) is 0

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
exports.isAnyOf = (searchString, stringArray) ->
  stringArray.some((elem) -> elem.localeCompare(searchString, 'en-US') == 0)

exports.parseElementText = (xmlNode) ->
  content = xmlNode.substr(0, xmlNode.length - "</div>".length) # remove closing div tag
  content = content.slice(content.indexOf(">") + 1)             # remove opening div tag
  content

#exports.arrayToMap = (array) ->
  #map[obj[key]] = element for element in array 

exports.logObject = (obj) -> console.log(JSON.stringify obj, null, 2) 
