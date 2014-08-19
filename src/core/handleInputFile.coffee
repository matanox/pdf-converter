#
# Fetch a file selected by the user user ink file picker (https://www.inkfilepicker.com/)
# Can switch to uploadcare.com or roll own...
#

convert    = require './convert'
extract    = require './extract'
util       = require '../util/util'
getFromUrl = require 'request'
fs         = require 'fs'
winston    = require 'winston'
logging    = require '../util/logging' 

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
  # inkUrl would be replaced by that other competing better service
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

    # initialize a context object, to be passed around
    context = 
      runID : req.query.runID

    baseFileName = req.query.localLocation.replace('.pdf', '')

    logging.logGreen("""Started handling input file: #{baseFileName}. Given run id is: #{context.runID}""")      

    docLogger = util.initDocLogger(baseFileName)
    docLogger.info('logger started')   

    outFile = setOutFile(baseFileName)
    convert.go(context, outFile, docLogger, req, res)
