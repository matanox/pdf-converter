require "fs"
util = require "../util"
css  = require "../css"
html = require "../html"

#
# Extract text content and styles from html
#
exports.go = (req, res) ->
  path = '../local-copies/' + 'html-converted/' 
  name = req.query.name
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString()

  divs = html.removeOuterDivs(rawHtml)
  ourDivRepresentation = (html.representDiv div for div in divs) 
  html.stripSpanWrappers(div) for div in ourDivRepresentation
  realStyles = css.simpleGetStyles(rawHtml ,path + name + '/') # send along the path to the folder

  #util.logObject()
  util.logObject(ourDivRepresentation)

  res.write "read raw html of length " + rawHtml.length + " bytes"

  res.end
