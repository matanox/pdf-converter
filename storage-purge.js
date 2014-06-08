// Generated by CoffeeScript 1.6.3
var clean, clearBucket, delete_key, delete_keys, riak;

riak = require('riak-js').getClient({
  host: "localhost",
  port: "8098"
});

delete_key = function(bucket, key) {
  return riak.remove(bucket, key);
};

delete_keys = function(bucket, keys) {
  console.log("looking for keys in bucket " + bucket);
  return keys.forEach(function(key) {
    console.log("bucket '" + bucket + "': deleting key " + key);
    return delete_key(bucket, key);
  });
};

clearBucket = function(bucket) {
  return riak.keys(bucket, function(err) {
    return console.dir(err);
  }).on('keys', function(keys) {
    return delete_keys(bucket, keys);
  }).on('end', function() {
    return null;
  }).start();
};

clean = function() {
  console.log('storage purge starting...');
  clearBucket('tokens');
  clearBucket('pdf');
  return clearBucket('html');
};

console.log("");

console.log("ATTENTION!!! if not interupted the riak db will be cleaned up in 30 seconds");

console.log("");

setTimeout(clean, 30000);
