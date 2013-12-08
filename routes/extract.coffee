require "fs"
util = require "../util"
css = require "../css"

#
# Extract text content and styles from html
#
exports.go = (req, res) ->
  path = '../local-copies/' + 'html-converted/' 
  name = req.query.name
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString()
  divs = util.removeOuterDivs(rawHtml)
  divsContent = (util.simpleGetDivContent div for div in divs) 
  res.write "read raw html of length " + rawHtml.length + " bytes"

  util.logObject(divs)

  css.simpleGetStyles(rawHtml ,path + name + '/') # send along the path to the folder

  res.end
