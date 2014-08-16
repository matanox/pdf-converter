ulimit -n 4096
riak start
echo "listing all buckets"
curl -i http://localhost:8098/riak?buckets=true
echo "listing keys of sample bucket"
curl -i http://localhost:8098/buckets/pdf/keys?keys=true
echo "to list a specific object, use curl -i http://localhost:8098/buckets/pdf/keys/objectKey"
echo "to delete a specific object, use curl -v -X DELETE http://127.0.0.1:8098/buckets/file/keys/objectKey"
