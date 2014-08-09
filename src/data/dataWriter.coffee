#
# Abstraction enabling the storage of data created as the processing of an input file, 
# such that it is left organized by data type, for an offline process or human to consume.
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

myWriter = require './writer'
logging  = require '../util/logging' 
util     = require '../util/util'

docsDataDir = 'docData'
exports.docsDataDir = docsDataDir

files = {} # dictionary to hinge writers used for each input pdf file

#
# The public writer interface of this module. Currently, Winston logger based.
# (initializes a physical writer for the data type if not already initialized)
#
exports.write = (inputFileName, dataType, data, cnsl) ->
  unless files[inputFileName]?
    files[inputFileName] = {} 
    console.log """clickable data directory link: """ + """file://#{process.cwd()}/#{docsDataDir}/""" + encodeURIComponent?(inputFileName)

  #
  # Initialize data writer if not already initialized
  #
  unless files[inputFileName][dataType]?

    logging.cond """opening writer for #{dataType}""", 'dataWriter'

    util.mkdir(docsDataDir, inputFileName)
   
    now = new Date()
    nameBase = docsDataDir + '/' + inputFileName + '/' + dataType + '-' + now.toISOString() + '.out' 

    writer = new myWriter(nameBase)
    
    logging.cond """Data writing for [#{inputFileName}], [#{dataType}] is going to #{nameBase}""", 'dataWriter'

    files[inputFileName][dataType] = writer

  #
  # write the data
  #
  files[inputFileName][dataType].write(data)

  #
  # mirror to console if requested
  #
  if cnsl?
    logging.logBlue data

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
