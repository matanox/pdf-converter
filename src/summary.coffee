assert           = require 'assert' 
util             = require './util/util'
logging          = require './util/logging' 
analytic         = require './util/analytic'
rdbms            = require './storage/rdbms/rdbms' 
#dataWriter       = require '../data/dataWriter'

tmpDir          = require('os').tmpdir()
fs              = require 'fs'
exec            = require './util/exec'

getQuerySingleResult = (resultArray) ->
  
  if resultArray.length is 1
    resultObj = resultArray[0]
    return resultObj[Object.keys(resultObj)[0]]

  return null  
  #else throw """query intended to result in one item resulted in #{resultArray.length}"""

serveInEditor = (docName, dataArray) ->
  tmpFile = """#{tmpDir}/#{docName}"""
  fs.writeFileSync(tmpFile, dataArray.join('\n'))
  exec('subl', [tmpFile], ()->)

#
#
#
query = () ->
  knex = rdbms.knex
  runID = null
  knex('runIDs').max('order')
    .then((result) ->
      lastRun = getQuerySingleResult(result)
      unless lastRun
        throw 'No data found'
      #console.log lastRun
      knex.select('runID').from('runIDs').where({order: lastRun})
    )
    .then((result) ->
      runID = getQuerySingleResult(result)
      console.log runID
      exec('subl', ['-n'], ()->)
      knex.select('docName').from('runs').where({runID: runID}).pluck('docName')
    )
    .map((docName) -> 
      #console.log docName
      knex.select('sentence').from('sentences').where({runID: runID, docName: docName}).pluck('sentence')
        .then((result) -> 
          #console.log docName
          #console.log result
          serveInEditor(docName, result)
      )    
    )

query()