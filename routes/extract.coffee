require "fs"
util = require "../myStringUtil"

#
# Filter the raw html for only divs that do not contain an inner div
# that's because we don't care about wrapper divs that don't contain text content,
# at least with html2pdfEX as the original source.
#
removeOuterDivs = (string) ->
  regex = new RegExp("<div((?!div).)*</div>", "g") # g indicates to yield all, not just first match
  return string.match(regex) 

#
# Extract text content and styles from html
#
exports.go = (req, res) ->
  rawHtml = fs.readFileSync("../local-copies/" + "html-converted/" + req.query.file).toString()
  divs = removeOuterDivs(rawHtml)
  divsContent = (util.simpleGetDivContent div for div in divs) 

  res.send "read raw html of length " + rawHtml.length + " bytes"
