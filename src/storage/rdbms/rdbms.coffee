# https://github.com/tgriesser/knex
# to open a mysql prompt from the terminal: mysql -u root -p

logging = require '../../util/logging' 
exec    = require '../../util/exec'

#
# Tables definition
#
docTables = 
  [
    name: 'sentences'
    fields:
      sentence: 'long-string'
   ,
    name: 'headers'
    fields:
      header: 'short-string' 
      level:  'natural-number'
   ,
    name: 'abstract'
    fields:
      abstract: 'long-string'
   ,
    name: 'title'
    fields:
      title: 'short-string' 
      
  ]

docTables.forEach((table) -> table.type = 'docTable')

tables = docTables

tables.forEach((table) ->
  switch table.type 
    when 'docTable' 
      table.fields.docName = 'short-string'
      table.fields.runID   = 'short-string'
)

#
# database specific settings
#
maxDbStrLength = 20000 # the mysql limitation

connection =
  host:     'localhost'
  user:     'articlio'
  database: 'articlio'
  charset:  'utf8'


#
# Returns a connection to the database.
#
exports.connect = connect = () ->
  knex = require("knex")(
    dialect: "mysql"
    connection: process.env.DB_CONNECTION_STRING or connection
  )

#
# Purge database tables. Not currently in use, as we just remove the entire database to purge it
#
purge = () ->

  conn = connect()

  tables.forEach((table) -> 
    conn.schema.dropTableIfExists(table.name)
  )

#
# Initialize the database tables (after the database and database user have already been initialized)
#
init = () ->

  conn = connect()

  for table in tables
    
    conn.schema.createTable(table.name, (newTable) ->
      for field of table.fields
        type = table.fields[field]
        switch type
          when 'short-string'
            newTable.string(field)
          when 'long-string'
            newTable.string(field, maxDbStrLength)
          when 'natural-number'
            newTable.integer(field)
          else
            logging.logRed """unidentified field type #{field}"""

    ).catch((error) -> 
        logging.logRed error
        logging.logRed 'database reinitialization failed'
        return false)

  console.log 'database ready for action'

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