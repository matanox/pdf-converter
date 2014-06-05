convert = require './convert'
extract = require './extract'
util    = require '../util'
getFromUrl = require 'request'
fs = require 'fs'
winston = require 'winston'

#
# * Fetches the upload from Ink File Picker (writing it into local file).
# * If it works - invoke the passed along callback function.
# 
fetch = (inkUrl, outFile, docLogger, req, res, callOnSuccess) ->
    
    #outFile = inkUrl + '.pdf';
    download = getFromUrl(inkUrl, (error, response, body) ->
      if (not error and response.statusCode is 200)
          callOnSuccess(outFile, docLogger, req, res)
      else
        console.log "fetching from InkFilepicker returned http status " + response.statusCode
        if error
          docLogger.info "fetching from InkFilepicker returned error " + error 
    ).pipe(fs.createWriteStream(outFile))

setOutFile = (baseFileName) -> "../local-copies/" + "pdf/" + baseFileName + ".pdf"

exports.go = (req, res) -> 
  
  #
  # Handle api request for inkUrl file (fetch the upload and pass on to conversion)
  #
  if req.query.inkUrl?
    inkUrl = req.query.inkUrl
    baseFileName = inkUrl.replace('https://www.filepicker.io/api/file/', '')
    docLogger = util.initDocLogger(baseFileName)
    docLogger.info('logger started')
    req.session.docLogger = docLogger

    outFile = setOutFile(baseFileName)
    fetch(inkUrl, outFile, docLogger, req, res, convert.go)

  #
  # Handle api request for local file
  # This api is for testing without hitting inkUrl
  # 
  if req.query.localLocation?
    baseFileName = req.query.localLocation.replace('.pdf', '')
    docLogger = util.initDocLogger(baseFileName)
    docLogger.info('logger started')   

    outFile = setOutFile(baseFileName)
    convert.go(outFile, docLogger, req, res)
