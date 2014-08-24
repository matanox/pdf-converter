#
# Get meta-data cotained in the pdf file, as much as any is contained
#

util = require './util'
logging = require './logging' 
dataWriter = require '../data/dataWriter'
exec = require('child_process').exec

module.exports = (context, localCopy, docLogger, params) ->
  
  execCommand = params.execCommand
  dataType    = params.dataType
  description = params.description

  #logging.log "Getting pdf file metadata using pdfinfo"
  util.timelog context, description
  

  execCommand +=  ' ' + '"' + localCopy + '"'
  #logging.log 'issuing command ' + execCommand

  exec execCommand, (error, stdout, stderr) ->
    dataWriter.write context, dataType, execCommand + "'s stdout: \n" + stdout
    dataWriter.write context, dataType, execCommand + "'s stderr: \n" + stderr
    if error isnt null
      dataWriter.write context, dataType, execCommand + "'sexec error: " + error
    else
      util.timelog context, description
      meta = {'raw': stdout, 'stderr': stderr}
      




      