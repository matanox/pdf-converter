# https://github.com/tgriesser/knex
# to open a mysql prompt from the terminal: mysql -u root -p

logging = require '../../util/logging' 
exec    = require '../../util/exec'
Promise = require 'bluebird'

#
# Tables definition
#

docTablesDefinition = 
  [
    name: 'sentences'
    fields:
      sentence: 'long-string'
   ,
    name: 'abstract'
    fields:
      abstract: 'long-string'
   ,
    name: 'title'
    fields:
      title: 'short-string' 
   ,
    name: 'headers'
    fields:
      level:            'natural-number'
      tokenId:          'natural-number'
      header:           'short-string'
      detectionComment: 'short-string'
   ,
    name  : 'properties'
    fields: 
      propName:  'short-string'
      propValue: 'short-string'
  ]

docTablesDefinition.forEach((table) -> table.type = 'docTable')

diffsTable = 
  [
    type: 'diffs'
    name: 'diffs'
    fields:
      docName:      'short-string'
      dataType:     'short-string'
      editDistance: 'natural-number'
      SESlink:      'short-string'
      run1ID:       'short-string'
      run2ID:       'short-string'
      run1link:     'short-string'
      run2link:     'short-string'
  ]

tableDefs = docTablesDefinition.concat diffsTable
tableDefs.forEach((table) ->
  switch table.type 
    when 'docTable' 
      table.fields.docName = 'short-string'
      table.fields.runID   = 'short-string'
)

#
# database specific settings
#

connection =
  host:     'localhost'
  user:     'articlio'
  database: 'articlio'
  charset:  'utf8'

maxDbStrLength = 20000 # the mysql-specific limitation

#
# mysql connection pool definition
#
knex = require("knex")(
  dialect: "mysql"
  connection: process.env.DB_CONNECTION_STRING or connection)

#
# Returns a connection to the database - bypassing the global knex connection pooling. Not in use.
#
exports.connect = connect = () ->
  knex = require("knex")(
    dialect: "mysql"
    connection: process.env.DB_CONNECTION_STRING or connection
  )

reqCounter   = 0
successCount = 0
error        = false

#
# Writing data to the rdbms
#
write = (context, dataType, mapping) ->
  
  reqCounter += 1
  #logging.logYellow reqCounter

  if error 
    logging.logRed 'rdbms writing failed, now skipping all forthcoming rdbms writes.'
    return

  knex.insert(mapping).into(dataType)
    .catch((error) -> 
      logging.logRed error
      console.dir error
      logging.logRed """writing to rdbms for data type #{dataType} failed"""
      error = true
      return false
    )
    .then((rows) -> 
      successCount += 1
      #logging.logGreen successCount
    )

  return true

#
# Maps data to the correct table field/s, and send off to actual writing
#
dataMap = (context, dataType, data) ->
  switch dataType
    when 'sentences'

      mapping = # map from CoffeeScript variable names to table field names
        sentence : data
        docName  : context.name
        runID    : context.runID

      return mapping

    when 'abstract'
      mapping = # map from CoffeeScript variable names to table field names
        abstract : data
        docName  : context.name
        runID    : context.runID
      return mapping
      
    when 'title'
      mapping = # map from CoffeeScript variable names to table field names
        title    : data
        docName  : context.name
        runID    : context.runID
      return mapping
      
    when 'headers'
      mapping = # map from CoffeeScript variable names to table field names
        docName  : context.name
        runID    : context.runID

      for key of data
        mapping[key] = data[key]

      return mapping

    when 'diffs'
      mapping = {}
      for key of data
        mapping[key] = data[key]

      return mapping

    else 
      #logging.logYellow """some data was not successfully mapped and could not be persisted for #{context.name}, #{dataType} - no mapping for #{dataType}"""
      return undefined


exports.write = (context, dataType, data) ->
  inputFileName = context

  if Array.isArray(data)
    dataArray = data
    mapping = dataArray.map((data) -> dataMap(context, dataType, data))
  else
    mapping = dataMap(context, dataType, data)
  
  if mapping?
    write(context, dataType, mapping)       
    
#
# Purge database tables. Not currently in use, as we just remove the entire database to purge it
#
purge = () ->

  tableDefs.forEach((table) -> 
    knex.schema.dropTableIfExists(table.name)
  )

#
# Initialize the database tables (after the database and database user have already been initialized)
#
init = () ->

  # as per knex api, a callback function to create table columns for a table already just created
  tableHandler = (tableDef, table) ->
    for field of tableDef.fields
      type = tableDef.fields[field]
      switch type
        when 'short-string'
          table.string(field)
        when 'long-string'
          table.string(field, maxDbStrLength)
        when 'natural-number'
          table.integer(field)
        else
          error = """unidentified field type #{field} specified in table definition of table #{tableDef.name}"""
          logging.logRed error
          throw error

    return true

  #conn = connect()

  tablesCreated = tableDefs.map((tableDef) ->
      boundTableHandler = tableHandler.bind(undefined, tableDef)        # early bound derivation for callback
      return knex.schema.createTable(tableDef.name, boundTableHandler)  # callback will be called when table has been created
    )

  Promise.all(tablesCreated).then(() -> # all promises successfully fulfilled
                               knex.destroy(()->)
                               console.log 'database ready for action')
                            .catch((error) -> # if there was an error on any of the promises
                               logging.logRed 'database reinitialization failed'
                               return false)


#
# initialize the database from A to Z.
# if it is already there, purge it first. 
#
exports.reinit = reinit = () ->
  exec('src/storage/rdbms/rdbms-recreate.sh', null, (success) -> 
    if success 
      console.log 'database definition and database user clean and ready'
      init()
    else 
      console.error 'database reinitialization failed - could not recreate database or database user'
  )