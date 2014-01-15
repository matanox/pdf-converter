util = require("./util")
exports.storePdfMetaData = (localCopy) ->
  
  console.log "Getting pdf file metadata using pdfinfo"
  util.timelog "Getting pdf file metadata using pdfinfo"
  
  execCommand = 'pdfinfo -meta' + ' '
  execCommand += localCopy
  console.log execCommand
  exec execCommand, (error, stdout, stderr) ->
    console.log executable + "'s stdout: " + stdout
    console.log executable + "'s stderr: " + stderr
    if error isnt null
      console.log executable + "'sexec error: " + error
    else
      util.timelog "Getting pdf file metadata using pdfinfo"
      meta = {raw: stdout, stderr: stderr}
      console.dir(meta)



      