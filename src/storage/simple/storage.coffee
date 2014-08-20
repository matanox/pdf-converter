#
# Interface to storage for storing large files rather than "data" -
# used to store and retrieve pdf, derived html, derived tokens after serializing them
#

util =    require '../../util/util'
logging = require '../../util/logging' 
riak =    require('riak-js').getClient({host: "localhost", port: "8098"}) # alternative node riak client - https://github.com/nathanaschbacher/nodiak
fs =      require 'fs'

exports.store = (context, bucket, fileContent, docLogger) ->
  filename = context.name

  #
  # TODO: handle case that file already exists
  # TODO: handle riak error (winston email notifying of it etc.)
  # TODO: handle duplicate file content via md5 (or other) hash
  # TODO: add authentication to the data store for production
  # TODO: tune/set riak bucket replication parameters
  # Optional: check out availability of riak cloud service
  #

  util.timelog context, "storing file to clustered storage"
  
  # The riak driver apparently uses the http riak api, which fails if not URI encoded -
  # so we URI encode to pass safely through http. Riak seems to unencode before storing the key,
  # so this is just for passing safely through the api, and not being stored URI encoded.
  riak.save(bucket, encodeURIComponent(filename), fileContent, (error) -> 
    util.timelog context, "storing file to clustered storage"
    if error?
      logging.logRed "failed storing file #{filename} to clustered storage bucket #{bucket}, with error: #{error}")

exports.fetch = (bucket, filename, callback) ->
  util.timelog "fetching file from clustered storage"
  riak.get(bucket, filename, (error, fileContent) ->
    util.timelog context, "fetching file from clustered storage"
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
 