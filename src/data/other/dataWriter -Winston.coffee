#
# Abstraction enabling the storage of data created out of an input file, 
# such that it is left organized by data type, for an offline process or human to consume.
#
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

logging = require './util/logging' 
winston = require 'winston'
util    = require './util/util'

docDataDir = 'docData/'
exports.docDataDir = docDataDir

files = {} # dictionary for files that have writers

# the actual writing
winstonWrite = (writer, data) ->
  writer.info(data)

#
# The public writer interface of this module. Currently, Winston logger based.
# (initializes a physical writer for the data type if not already initialized)
#
exports.write = (inputFileName, dataType, data) ->
  unless files[inputFileName]?
    files[inputFileName] = {}

  #
  # Initialize data writer if not already initialized
  #
  unless files[inputFileName][dataType]?

    writer = new winston.Logger
    now = new Date()

    console.log """opening writer for #{dataType}"""

    util.mkdir(docDataDir, inputFileName)
    
    nameBase = docDataDir + '/' + inputFileName + '/' + dataType + '-' + now.toISOString() + '.out' 
    
    writer = new winston.Logger
      transports: [
        #new winston.transports.File
        #  name: 'file#json'
        #  filename: nameBase + '.json',
        #  json: true
        #  timestamp: false
        new winston.transports.File
          name: 'file#text'
          filename: nameBase,
          json: false
          timestamp: false
      ], exitOnError: false
    logging.cond """Data writing for [#{inputFileName}], [#{dataType}] is going to #{nameBase}""", 'dataWriter'

    files[inputFileName][dataType] = writer

  #
  # write the data
  #
  #console.log """writing to writer for #{dataType}"""
  #unless files[inputFileName][dataType].transports['file#text'].opening then console.log 'not opening'
  winstonWrite(files[inputFileName][dataType], data)

  return true

#
# Close all writers related to a certain file
#
closer = (inputFileName) ->
  console.log """closing writers for #{inputFileName}"""

  for writer of files[inputFileName]
    if files[inputFileName][writer].transports['file#text'].opening
      console.warn 'cannot close writer as it has not drained. queuing a retry.'
      setTimeout((() -> closer(inputFileName)), 2000) # this is a workaround as otherwise the Winston file writers don't really close
      return
    else
      #files[inputFileName][writer].clear() # should terminate all transports of the writer
      files[inputFileName][writer].close()
      delete files[inputFileName][writer]
     
  #if Object.keys(files[inputFileName]).length is 0
  #  delete files[inputFileName]

exports.close = (inputFileName) ->

  setTimeout((() -> closer(inputFileName)), 2000) # this is a workaround as otherwise the Winston file writers don't really close


    