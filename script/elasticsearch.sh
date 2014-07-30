/usr/share/elasticsearch/bin/elasticsearch
echo "getting the elasticsearch version..."
curl -XGET 'localhost:9200' 
echo "NOTE: curl -XPOST 'http://localhost:9200/_cluster/nodes/_local/_shutdown' to shutdown"
