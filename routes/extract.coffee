require "fs"
util = require "../myStringUtil"

#
# Extract text content and styles from html
#
exports.go = (req, res) ->
  rawHtml = fs.readFileSync("../local-copies/" + "html-converted/" + req.query.file).toString()
  divs = util.removeOuterDivs(rawHtml)
  divsContent = (util.simpleGetDivContent div for div in divs) 
  res.write "read raw html of length " + rawHtml.length + " bytes"

  util.simpleGetCssFiles(rawHtml)

  res.end




