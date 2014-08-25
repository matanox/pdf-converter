#
# Retreive data from the last run, and display it in sublime text
#

assert           = require 'assert' 
util             = require './util/util'
logging          = require './util/logging' 
analytic         = require './util/analytic'
rdbms            = require './storage/rdbms/rdbms' 
#dataWriter       = require '../data/dataWriter'

tmpDir          = require('os').tmpdir()
fs              = require 'fs'
Promise         = require 'bluebird'
exec            = Promise.promisify(require './util/exec')

getQuerySingleResult = (resultArray) ->
  
  if resultArray.length is 1
    resultObj = resultArray[0]
    return resultObj[Object.keys(resultObj)[0]]

  return null  
  #else throw """query intended to result in one item resulted in #{resultArray.length}"""

#
# Open result as a sublime view, relying on a temp file (which will be rewritten if already exists)
#
serveInEditor = (docName, dataArray, dataType) ->
  tmpFile = """#{tmpDir}/#{docName} (#{dataType})""" 
  fs.writeFileSync(tmpFile, dataArray.join('\n'))
  exec('subl', [tmpFile])

#
# Query the rdbms, and display results in sublime text
#
query = (dataType, field) ->
  knex = rdbms.knex
  runID = null
  #logging.logGreen """Opening summary for run ID #{runID}, #{dataType}..."""
  # get the chronologically last runID
  knex('runIDs').max('order')
    .then((result) ->
      lastRun = getQuerySingleResult(result)
      unless lastRun
        throw 'No data found'
      #console.log lastRun
      knex.select('runID').from('runIDs').where({order: lastRun})
    )
    # get all docs handled in that run 
    .then((result) ->
      runID = getQuerySingleResult(result)
      #console.log runID
      exec('subl', ['-n'])
      .then((execReturn) ->
        #console.log execReturn
        knex.select('docName').from('runs').where({runID: runID}).pluck('docName'))
    )
    # act for each such document
    .map((docName) -> 
      #console.log docName
      knex.select(field).from(dataType).where({runID: runID, docName: docName}).pluck(field)
        .then((result) -> 
          #console.log docName
          #console.log result
          serveInEditor(docName, result, dataType)
      )    
    ).then(() -> return true)
    .catch((error) ->
      logging.logYellow error
      logging.logYellow 'could not create data summary'
    )


query('sentences', 'sentence')
.then((rc) ->
  query('abstract', 'abstract')
  #setTimeout((()->query('abstract', 'abstract')), 500)
)