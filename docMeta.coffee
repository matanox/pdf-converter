#
# Get meta-data cotained in the pdf file, as much as any is contained
#s./sta

util = require './util'
logging = require './logging' 
dataWriter = require './dataWriter'
exec = require('child_process').exec

exports.storePdfMetaData = (name, localCopy, docLogger) ->
  
  #logging.log "Getting pdf file metadata using pdfinfo"
  util.timelog name, "Getting pdf file metadata using pdfinfo"
  
  execCommand = 'pdfinfo -meta' + ' '
  execCommand += '"' + localCopy + '"'
  #logging.log 'issuing command ' + execCommand

  exec execCommand, (error, stdout, stderr) ->
    dataWriter.write name, 'pdfMeta', execCommand + "'s stdout: \n" + stdout
    dataWriter.write name, 'pdfMeta', execCommand + "'s stderr: \n" + stderr
    if error isnt null
      dataWriter.write name, 'pdfMeta', execCommand + "'sexec error: " + error
    else
      util.timelog name, "Getting pdf file metadata using pdfinfo", docLogger
      meta = {'raw': stdout, 'stderr': stderr}
      




      