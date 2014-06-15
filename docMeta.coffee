#
# Get meta-data cotained in the pdf file, as much as any is contained
#

util = require './util'
logging = require './logging' 
exec = require('child_process').exec

exports.storePdfMetaData = (localCopy, docLogger) ->
  
  #logging.log "Getting pdf file metadata using pdfinfo"
  util.timelog "Getting pdf file metadata using pdfinfo"
  
  execCommand = 'pdfinfo -meta' + ' '
  execCommand += localCopy
  #logging.log 'issuing command ' + execCommand

  exec execCommand, (error, stdout, stderr) ->
    docLogger.info(execCommand + "'s stdout: " + stdout)
    docLogger.info(execCommand + "'s stderr: " + stderr)
    if error isnt null
      docLogger.error execCommand + "'sexec error: " + error
    else
      util.timelog "Getting pdf file metadata using pdfinfo", docLogger
      meta = {'raw': stdout, 'stderr': stderr}
      




      