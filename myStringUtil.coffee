endsWith = (string, match) ->
  string.indexOf(match) is string.length - match.length

startsWith = (string, match) ->
  string.indexOf(match) is 0

contains = (string, match) ->
  string.indexOf(match) isnt -1

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
  console.log xmlNode
  console.log content + "\n" + "\n"
  content

strip = (string, prefix, suffix) ->
  if !startsWith(string, prefix)
    throw("Cannot strip string of the supplied prefix")
  if !endsWith(string, suffix)
    throw("Cannot strip string of the supplied suffix")

  string.slice(string.indexOf(prefix)+prefix.length, string.indexOf(suffix))      

simpleGetCssFileNames = (string) ->
  prefix = '<link rel="stylesheet" href="'
  suffix = '"/>'
  regex = new RegExp(prefix + '.*' + suffix, 'g') # g indicates to yield all, not just first match
  linkStripper = (string) -> strip(string, prefix, suffix)

  cssFiles = (linkStripper stylesheetElem for stylesheetElem in string.match(regex)) # a small for comprehension
  cssFiles
  # console.log cssLinks

appendPrefix = (string) -> '../local-copies/' + 'html-converted' + string

exports.simpleGetCssFiles = (string) ->
  cssFilePaths = (appendPrefix string for string in simpleGetCssFileNames(string))
  console.log cssFilePaths

  
