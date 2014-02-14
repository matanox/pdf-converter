#
#  http://www.elasticsearch.org/guide/en/elasticsearch/client/javascript-api/master/api-reference.html
#  http://www.elasticsearch.org/guide/en/elasticsearch/client/javascript-api/master/index.html
#  http://www.elasticsearch.org/blog/client-for-node-js-and-the-browser/
#  https://github.com/elasticsearch/elasticsearch-js


elasticsearch = require 'elasticsearch'

###

# Connect to localhost:9200 and use the default settings
es = new elasticsearch.Client()

# Connect the client to two nodes, requests will be
# load-balanced between them using round-robin
client = elasticsearch.Client(hosts: [
  "elasticsearch1:9200"
  "elasticsearch2:9200"
])
###

###
# Connect to this host using https, basic auth,
# a path prefix, and static query string values
client = new elasticsearch.Client(host: "https://user:password@elasticsearch1/search?app=blog")
###

# Connect to the this host's elasticsearch, then connect to more nodes on the 
# elasticsearch cluster it belongs to (by sniffing for the rest of the cluster right away and on interval).
esClient = elasticsearch.Client(
  host: "localhost:9200"
  sniffOnStart: true
  sniffInterval: 300000
  apiVersion: '1.0'
)

test = () ->
  esClient.create(
    {
      index: 'meta'
      type:  'test'
      body:
      	text: 'bla'
      	article: 'bla'
    }, (error) -> console.error(error) if error?)

