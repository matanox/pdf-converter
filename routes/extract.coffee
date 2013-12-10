require "fs"
util   = require "../util"
css    = require "../css"
html   = require "../html"
output = require "../output"

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
  realStyles = css.simpleFetchStyles(rawHtml ,path + name + '/') # send along the path to the folder

  util.logObject(realStyles)
  #util.logObject(ourDivRepresentation)

  outputHtml = ourDivRepresentation
  output.serveOutput(outputHtml, name, res)

  # res.sendfile('../local-copies/' + 'output/' + name + ".html")

  # res.send("read raw html of length " + rawHtml.length + " bytes")
  