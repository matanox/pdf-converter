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
  styledText = (html.deconstructDiv div for div in divs) 
  styles = css.simpleGetStyles(rawHtml ,path + name + '/') # send along the path to the folder

  #util.logObject(styledText)
  util.logObject(styles)
  
  res.write "read raw html of length " + rawHtml.length + " bytes"

  res.end
