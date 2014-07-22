#
# Interface to storage for storing large files rather than "data" -
# used to store and retreive pdf, derived html, derived tokens after serializing them
#

util =    require './util'
logging = require './logging' 
riak =    require('riak-js').getClient({host: "localhost", port: "8098"})
# alternative node riak client - https://github.com/nathanaschbacher/nodiak
fs =      require 'fs'

exports.store = (bucket, filename, fileContent, docLogger) ->
  #
  # TODO: handle case that file already exists
  # TODO: handle riak error (winston email notifying of it etc.)
  # TODO: handle duplicate file content via md5 (or other) hash
  # TODO: add authentication to the data store for production
  # TODO: tune/set riak bucket replication parameters
  # Optional: check out availability of riak cloud service
  #

  util.timelog filename, "storing file to clustered storage"
  
  riak.save(bucket, filename, fileContent, (error) -> 
    util.timelog filename, "storing file to clustered storage"
    if error?
      console.error("failed storing file to clustered storage, with error: #{error}"))

exports.fetch = (bucket, filename, callback) ->
  util.timelog "fetching file from clustered storage"
  riak.get(bucket, filename, (error, fileContent) ->
    util.timelog filename, "fetching file from clustered storage"
    if error?
      #console.error("failed fetching file from clustered storage")
      callback(false)
    else
      #util.timelog "fetching file from clustered storage"
      #console.log fileContent
      callback(fileContent))



###
riak.get('pdf', 'tXqIBGiBR5aMgxBQBOVY', (error, fileContent) ->
  if error
    logging.log(error)
  else
    logging.log(fileContent)
  fs.writeFileSync('back-from-riak.pdf', fileContent))
###



###
  #
  # On hold rethinkdb integration - using Riak for pdf2htmlEX caching for now
  #
  dbms   =  require 'rethinkdb'
  dbms.connect( {host: 'localhost', port: 28015}, (err, connection) ->
    if (err) then throw err
    dbms.db('test').tableCreate('file_hashes').run(connection, (err, result) ->
        if (err) then throw err;
        console.log(JSON.stringify(result, null, 2))
      )
  )
  ###
 