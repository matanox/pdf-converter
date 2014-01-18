util = require './util'
logging = require './logging' 
riak = require('riak-js').getClient({host: "localhost", port: "8098"})

exports.store = (bucket, filename, file, docLogger) ->
  #
  # TODO: handle case that file already exists
  # TODO: handle riak error (winston email notifying of it etc.)
  # TODO: handle duplicate file content via md5 (or other) hash
  # TODO: add authentication to the data store for production
  # TODO: tune/set riak bucket replication parameters
  # Optional: check out availability of riak cloud service
  #
  fs = require 'fs'
  util.timelog "storing file to clustered storage"
  # alternative node riak client - https://github.com/nathanaschbacher/nodiak
  fileContent = fs.readFileSync(file)
  riak.save(bucket, filename, fileContent, (error) -> 
    util.timelog "storing file to clustered storage", docLogger
    if error?
      docLogger.error("failed storing file to clustered storage")
      return false
    return true)





  ###
  riak.get('pdf', 'tXqIBGiBR5aMgxBQBOVY', (error, fileContent) ->
    if error
      logging.log(error)
    else
      logging.log(fileContent)
    fs.writeFileSync('back-from-riak.pdf', fileContent))
  ###



