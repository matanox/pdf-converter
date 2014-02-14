util = require './util'
es   = require './elasticsearch'

add = (string, type, article, tagger) -> 
  esClient.create(
    {
      index: 'fluff'
      type:  type
      body:
      	text:    text
      	article: article
      	tagger:  tagger
    }, (error) -> console.error(error) if error?)


fluff = {}
exports.fluff = fluff

#
# Load the fluff data so that it can be used per document
#
exports.load = () ->
  util.timelog('Loading fluff database')  
  util.timelog('Loading fluff database')  