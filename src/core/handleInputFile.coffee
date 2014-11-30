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

nconf = require('nconf')
dataOutDir = nconf.get("locations")["pdf-extraction"]["asData"]
textOutDir = nconf.get("locations")["pdf-extraction"]["asText"]
JATSOutDir = nconf.get("locations")["pdf-extraction"]["asJATS"]


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

initOutDirs = (baseFileName) -> 
  util.mkdirRecursive(dataOutDir)
  util.mkdirRecursive(textOutDir)
  util.mkdirRecursive(JATSOutDir)

exports.go = (req, res) -> 
  
  #
  # Handle api request one file
  # 

  if req.query.localLocation?

    if req.query.runID
      runID = req.query.runID
    else
      #logging.logRed("""Bad request. runID parameter missing in request.""")
      runID = util.simpleGenerateRunID()
      logging.logRed("""Augmenting request with runID #{runID}""")

    # initialize a context object, to be passed around
    fullFileName = req.query.localLocation
    baseFileName = fullFileName.substring(fullFileName.lastIndexOf('/')+1).replace('.pdf', '')

    context = 
      runID : runID
      name  : baseFileName

    logging.logGreen("""Started handling input file: #{fullFileName}. Given run id is: #{context.runID}""")      

    docLogger = util.initDocLogger(baseFileName)
    docLogger.info('logger started')   

    #outFile = initOutDirs(baseFileName)
    initOutDirs(baseFileName)
    convert.go(context, fullFileName, docLogger, req, res)
    return

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
    return
  
  logging.logRed("""Bad request""")
  res.send(500) 