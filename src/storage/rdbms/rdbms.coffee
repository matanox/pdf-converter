# https://github.com/tgriesser/knex
# to open a mysql prompt from the terminal: mysql -u root -p

exec = require '../../util/exec'

#
# Tables definition
#
docTables = [
              name: 'sentences'
             ,
              name: 'headers'
            ]

docTables.forEach((table) -> table.type = 'docTable')

tables = docTables

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
      newTable.increments('id')  # auto-incrementing id field
      if table.type is 'docTable' 
        newTable.string('docName')
        newTable.string('text', maxDbStrLength)
        newTable.string('runID')
    ).catch((error) -> 
        console.error error
        console.error 'database reinitialization failed')


  console.log 'database ready for action'

#
# initialize the database from A to Z.
# if it is already there, purge it first. 
#
exports.reinit = reinit = () ->
  exec('src/storage/rdbms/rdbms-recreate.sh', null, (success) -> 
    if success 
      console.log 'database and database user clean and ready'
      init()
    else 
      console.error 'database reinitialization failed - could not recreate database or database user'
  )