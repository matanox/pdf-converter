#
# Clean up the riak db
#
# Usage (assunming this file compiled to .js): node storage-purge 
# 
# To view all buckets on the command line: curl -i http://localhost:8098/buckets?buckets=true
#

riak = require('riak-js').getClient({host: "localhost", port: "8098"})

delete_key = (bucket,key) ->
    riak.remove(bucket, key)

delete_keys = (bucket, keys) -> 
  console.log """looking for keys in bucket #{bucket}"""
  keys.forEach((key) ->
    console.log """bucket '#{bucket}': deleting key #{key}"""
    delete_key(bucket, key))

clearBucket = (bucket) ->
  riak.keys(bucket, (err) -> console.dir err)
    .on('keys', (keys) -> delete_keys(bucket, keys))
    .on('end', () -> null)
    .start()

clean = () ->
  console.log 'storage purge starting...'
  clearBucket('tokens')
  clearBucket('pdf')
  clearBucket('html')

console.log ""
console.log "ATTENTION!!! if not interupted the riak db will be cleaned up in 30 seconds"
console.log ""
setTimeout(clean, 30000)

