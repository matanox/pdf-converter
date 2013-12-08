# crepl = require 'coffee-script/lib/coffee-script/repl'

endsWith = (string, match) ->
  string.indexOf(match) is string.length - match.length

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

  string.slice(string.indexOf(prefix)+prefix.length, string.indexOf(suffix))      

# Utilty function for checking if a string matches any of a given set of strings.
# Regex building could be an alternative implementation...
exports.isAnyOf = (searchString, stringArray) ->
  stringArray.some((elem) -> elem.localeCompare(searchString, 'en-US') == 0)

#
# Filter the raw html for only divs that do not contain an inner div
# that's because we don't care about wrapper divs that don't contain text content,
# at least with html2pdfEX as the original source.
#
exports.removeOuterDivs = (string) ->
  regex = new RegExp('<div((?!div).)*</div>', 'g') # g indicates to yield all, not just first match
  return string.match(regex) 

#
# Extracts the text of a div element
#
exports.simpleGetDivContent = (xmlNode) ->
  
  # assumes there are no nested divs inside xmlNode
  
  # console.log(xmlNode.length)
  # console.log('</div>'.length)
  content = xmlNode.substr(0, xmlNode.length - "</div>".length) # remove closing div tag
  
  # console.log(content)
  # console.log(content.match('>'))
  content = content.slice(content.indexOf(">") + 1) # remove opening div tag
  # console.log xmlNode
  # console.log content + "\n" + "\n"
  content
