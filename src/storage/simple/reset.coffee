#
# Clean up the riak db
#
# A utility source file, not (currently) invoked by the application
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

purge = () ->
  console.log 'storage purge starting...'
  clearBucket('tokens')
  clearBucket('pdf')
  clearBucket('html')

wait = 5
console.log ""
console.log """ATTENTION!!! if not interupted cached data for pdf, html, and tokens will be purged in #{wait} seconds"""
console.log ""
setTimeout(purge, wait * 1000)

