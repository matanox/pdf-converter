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

# Takes a raw Div, and creates a representation holding
# its content and style such that it can be worked with
exports.representDiv = (xmlNode) ->
  # assumes there are no nested divs inside xmlNode
  text = util.parseElementText(xmlNode)
  styles = parseCssClasses(xmlNode)
  return {text, styles}

#
# Collapses a div into its cummulative text content by stripping
# each span's header and trailer tags. This is somewhat pdf2htlmEX
# specific in assuming divs only contain spans (if at all), and only 
# contain spans that don't specify styles we need to bother with.
#
# This is ugly as this function accepts the whole div and not just
# its text, but otherwise the function couldn't change the div's text 
# given Javascript's argument passing realities - 
# http://stackoverflow.com/questions/6605640/javascript-by-reference-vs-by-value
#
exports.stripSpanWrappers = (div) ->
  spanBegin = new RegExp('<span.*?>', 'g')
  spanEnd 	= new RegExp('</span>', 'g')
  div.text = div.text.replace(spanBegin, '') 
  div.text = div.text.replace(spanEnd, '')
 