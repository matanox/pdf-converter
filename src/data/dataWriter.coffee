#
# Abstraction enabling the storage of data created as the processing of an input file
# such that it is left organized by data type, for an offline process or human to consume.
# 
# This is for both logging what you'd consider data and what you'd consider logging - 
# in line with an approach of making logging be treated like a first class type of data, 
# and encouraging writing as first-class data information that may be typically 
# lost in the legacy mindset of logging.
#
# right now it does that by writing each data type to a file bearing the type's name.
# I.e. the result of using this module should be a directory for the input file's data,
# where each file contains a separate type of data generated for it. But later refactoring
# can alternatively store the data to a different facility or file scheme. E.g. it can write everything 
# to a nosql store, elasticsearch, or to e.g. a single file with json meta-tags per data type. As long
# as this module writes the data efficiently, such that it can be retreived efficiently by type,
# it performs on its design goal.
#
# it may also duplicate the writing for establishing either redundancy or for allowing offline
# querying of the data through more than one type of data store.
#
# funnel all data writing through here - and we are safe flexibly stacking data stores.
#

myWriter = require './writer'
logging  = require '../util/logging' 
util     = require '../util/util'
rdbms    = require '../storage/rdbms/rdbms' 
fs       = require 'fs'

nconf = require('nconf')
PDFinputPath = nconf.get("locations")["pdf-extraction"]["asData"]

exports.docsDataDir = docsDataDir = PDFinputPath

files = {} # dictionary to hinge writers used for each input pdf file

#
# The public writer interface of this module. Currently, Winston logger based.
# (initializes a physical writer for the data type if not already initialized)
#

#
# Returns a filename to use.
# If necessary, creates the underlying directory.
#
exports.getReadyName = getReadyName = (context, dataType) ->
  inputFileName = context.name
  util.mkdir(docsDataDir, inputFileName)
  #now = new Date()
  return docsDataDir + '/' + context.name + '/' + dataType + '*' + context.runID + '.out' 

rdbmsWrite = (context, dataType, data, cnsl) -> rdbms.write(context, dataType, data)

#
# Simpler writer for bulk - 
# writes data, opening and closing the file at each invocation.
# writes in "append" mode, whether the file already exists or not doesn't matter.
# (currently using http://nodejs.org/api/fs.html#fs_fs_appendfile_filename_data_options_callback)
#
# TODO: add global counting of async writing callbacks or promisified invocations, 
#       that is checked upon program termination to check whether all writes have drained,
#       or otherwise notifies of failed or timed out writing
#
exports.writeArray = (context, dataType, dataArray) ->

  unless Array.isArray(dataArray)
    logging.logRed """writeBunch expects an array as input, writing for #{context}, #{dataType} ignored"""
    return

  rdbmsWrite(context, dataType, dataArray)
  
  fs.appendFile(getReadyName(context, dataType), dataArray.join('\n'))

#
# Single record async writer (ultimately delegating to lower level writer)
#
# TODO: add counting of async writing callbacks or promisified invocations, 
#       per context or data type, to enable tracking data drainage
#
exports.write = (context, dataType, data, cnsl) ->
  
  inputFileName = context.name

  unless dataType in ['stats', 'timers', 'partDetection'] # till those get sorted out or superseded
    rdbmsWrite(context, dataType, data, cnsl)

  if typeof data is 'object'
    dataSerialized = Object.keys(data).map((key) -> """#{key}: #{data[key]}""").join(', ')
    data = dataSerialized

  #
  # mirror to console if requested
  #
  if cnsl? then logging.logBlue data

  unless files[inputFileName]?
    files[inputFileName] = {} 
    console.log """clickable data directory link: """ + """file://#{process.cwd()}/#{docsDataDir}/""" + encodeURIComponent(inputFileName) + '/'

  #
  # Initialize data writer if not already initialized
  #
  unless files[inputFileName][dataType]?

    logging.cond """opening writer for #{dataType}""", 'dataWriter'

    dataFile = getReadyName(context, dataType)

    writer = new myWriter(dataFile)
    
    logging.cond """Data writing for [#{inputFileName}], [#{dataType}] is going to #{dataFile}""", 'dataWriter'

    files[inputFileName][dataType] = writer

  #
  # write the data
  #
  files[inputFileName][dataType].write(data)

  return true

#
# Close all writers related to a certain file
#
exports.close = (inputFileName) ->
  logging.cond """closing writers for #{inputFileName}""", 'dataWriter'

  for writer of files[inputFileName]
    logging.cond """writer to close: #{writer}""", logging.cond
    files[inputFileName][writer].close()
    
  delete files[inputFileName]  
