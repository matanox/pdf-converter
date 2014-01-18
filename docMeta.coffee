util = require './util'
logging = require './logging' 
exec = require('child_process').exec

exports.storePdfMetaData = (localCopy, docLogger) ->
  
  logging.log "Getting pdf file metadata using pdfinfo"
  util.timelog "Getting pdf file metadata using pdfinfo"
  
  execCommand = 'pdfinfo -meta' + ' '
  execCommand += localCopy
  logging.log 'issuing command ' + execCommand
  exec execCommand, (error, stdout, stderr) ->
    logging.log execCommand + "'s stdout: " + stdout
    logging.log execCommand + "'s stderr: " + stderr
    if error isnt null
      logging.log execCommand + "'sexec error: " + error
    else
      util.timelog "Getting pdf file metadata using pdfinfo"
      meta = {raw: stdout, stderr: stderr}
      console.dir(meta)



      