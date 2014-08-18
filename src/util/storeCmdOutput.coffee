#
# Get meta-data cotained in the pdf file, as much as any is contained
#

util = require './util'
logging = require './logging' 
dataWriter = require '../data/dataWriter'
exec = require('child_process').exec

module.exports = (context, localCopy, docLogger, params) ->
  name = context.name
  
  execCommand = params.execCommand
  writerType  = params.writerType
  description = params.description

  #logging.log "Getting pdf file metadata using pdfinfo"
  util.timelog name, description
  

  execCommand +=  ' ' + '"' + localCopy + '"'
  #logging.log 'issuing command ' + execCommand

  exec execCommand, (error, stdout, stderr) ->
    dataWriter.write context, writerType, execCommand + "'s stdout: \n" + stdout
    dataWriter.write context, writerType, execCommand + "'s stderr: \n" + stderr
    if error isnt null
      dataWriter.write context, writerType, execCommand + "'sexec error: " + error
    else
      util.timelog name, description
      meta = {'raw': stdout, 'stderr': stderr}
      




      