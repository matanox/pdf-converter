#
#
#

assert           = require 'assert' 
util             = require './util/util'
logging          = require './util/logging' 
analytic         = require './util/analytic'
rdbms            = require './storage/rdbms/rdbms' 
#dataWriter       = require '../data/dataWriter'

fs              = require 'fs'
Promise         = require 'bluebird'
exec            = Promise.promisify(require './util/exec')

#
# get the chronologically last runID
#
lastRun = () ->
knex('runIDs').max('order')
  .then((result) ->
    lastRun = getQuerySingleResult(result)
    unless lastRun
      throw 'No data found'
    #console.log lastRun
    knex.select('runID').from('runIDs').where({order: lastRun})
  )

#
# Forgiving column creation
#
# Creates column if it doesn't already exist,
# gracefully returning in both cases
#
createColumn = (table, column) ->

  knex.schema.hasTable(table, column).then((exists)->
      unless exists
        table(table).create(column)
    )
    .catch((error) -> 
      logging.logYellow error
      logging.logYellow """failed creating column #{column} in table #{table}"""
    )

createColumn('grading', 'fluff')