# https://github.com/tgriesser/knex
# to open a mysql prompt from the terminal: mysql -u root -p

docTables = [
              name: 'sentences'
             ,
              name: 'headers'
            ]

docTables.forEach((table) -> table.type = 'docTable')

tables = docTables

connection =
  host:     'localhost'
  user:     'articlio'
  password: 'articlio'
  database: 'articlio'
  charset:  'utf8'

exports.connect = connect = () ->
  knex = require("knex")(
    dialect: "mysql"
    connection: process.env.DB_CONNECTION_STRING or connection
  )

exports.init = init = () ->

  conn = connect()

  for table in tables
    console.dir table
    conn.schema.createTable(table.name, (newTable) ->
      newTable.increments('id')  # auto-incrementing id field
      if table.type is 'docTable' 
        console.log 'inside'
        newTable.string('docName')
        newTable.string('text')
    ).catch((error) -> console.error error)

exports.purge = purge = () ->

  conn = connect()

  tables.forEach((table) -> 
    conn.schema.dropTableIfExists(table.name)
  )

#purge()
init()