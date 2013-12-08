util = require('./util')

#
# Filter the raw html for only divs that do not contain an inner div
# that's because we don't care about wrapper divs that don't contain text content,
# at least with html2pdfEX as the original source.
#
exports.removeOuterDivs = (string) ->
  regex = new RegExp('<div((?!div).)*</div>', 'g') # g indicates to yield all, not just first match
  return string.match(regex) 

parseCssClasses = (xmlNode) ->
  # Build an array of the classes included by the div's "class=" statement.
  # Admittedly this is quite pdf2htmlEX specific parsing....
  
  regex = new RegExp("<div class=\".*?\"", 'g') # Regex match: Extract up to the end of
  cssClassesString = xmlNode.match(regex)		# 			   the classes string of a div 	
  cssClassesString = util.strip(cssClassesString[0], "<div class=\"", "\"") # Now strip the string
  
  # Regex match: Extract the class names
  regex = new RegExp("\\b\\S+?\\b", 'g') # first slash is for the string, not the regex
  cssClasses = cssClassesString.match(regex)
  cssClasses

exports.deconstructDiv = (xmlNode) ->
  # assumes there are no nested divs inside xmlNode
  text = util.parseElementText(xmlNode)
  styles = parseCssClasses(xmlNode)
  return {text, styles}
