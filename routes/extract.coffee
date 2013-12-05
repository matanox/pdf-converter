require "fs"
require "../myStringUtil"

exports.go = (req, res) ->
  rawHtml = fs.readFileSync("../local-copies/" + "html-converted/" + req.query.file).toString()
  #console.log rawHtml

  #
  # filter the raw html for only divs that do not contain an inner div
  #
  regex = new RegExp("<div((?!div).)*</div>", "g") # g indicates to yield all, not just first match
  divs = rawHtml.match(regex) 
  #console.log divs

  #console.log "here"

  #newDivs = (console.log div for div in divs) 

  

  res.send "read raw html of length " + rawHtml.length + " bytes"
