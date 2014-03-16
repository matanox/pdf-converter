util =    require './util'
logging = require './logging' 
riak =    require('riak-js').getClient({host: "localhost", port: "8098"})
# alternative node riak client - https://github.com/nathanaschbacher/nodiak
fs =      require 'fs'
crypto =  require 'crypto'
dbms   =  require 'rethinkdb'

exports.store = (bucket, filename, file, docLogger) ->
  #
  # TODO: handle case that file already exists
  # TODO: handle riak error (winston email notifying of it etc.)
  # TODO: handle duplicate file content via md5 (or other) hash
  # TODO: add authentication to the data store for production
  # TODO: tune/set riak bucket replication parameters
  # Optional: check out availability of riak cloud service
  #

  util.timelog "storing file to clustered storage"

  hasher = crypto.createHash('md5');

  fileContent = fs.readFileSync(file)

  util.timelog "hashing input file"
  hasher.update(fileContent)
  hash = hasher.digest('hex')
  util.timelog "hashing input file"
  console.log hash

  dbms.connect( {host: 'localhost', port: 28015}, (err, connection) ->
    if (err) then throw err
    dbms.db('test').tableCreate('file_hashes').run(connection, (err, result) ->
        if (err) then throw err;
        console.log(JSON.stringify(result, null, 2))
      )
  )
 
  riak.save(bucket, filename, fileContent, (error) -> 
    util.timelog "storing file to clustered storage", docLogger
    if error?
      docLogger.error("failed storing file to clustered storage"))

exports.fetch = (bucket, filename, callback) ->
  util.timelog "fetching file from clustered storage"
  riak.get(bucket, filename, (error, fileContent) ->
    if error?
      console.error("failed fetching file from clustered storage")
      return false
    else
      util.timelog "fetching file from clustered storage"
      console.log fileContent
      callback(fileContent))



  ###
  riak.get('pdf', 'tXqIBGiBR5aMgxBQBOVY', (error, fileContent) ->
    if error
      logging.log(error)
    else
      logging.log(fileContent)
    fs.writeFileSync('back-from-riak.pdf', fileContent))
  ###



