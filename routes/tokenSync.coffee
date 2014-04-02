util    = require '../util'
logging = require '../logging' 
css     = require '../css'
storage = require '../storage'
require 'stream'
riak   = require('riak-js').getClient({host: "localhost", port: "8098"})

exports.go = (req, res) ->
  #unless req.session.tokens? then return # replace with further error handling and logging here
  util.timelog """handling client ajax request for #{req.session.name}"""
  
  if req.session.tokenSequenceSerialized? # unless the token sequence was retreived from the data store
     console.log 'serving tokens from cache'
     res.end(req.session.tokenSequenceSerialized)     
  else
    console.log 'serving newly created tokens'
    tokens = req.session.tokens 

    tokenSequence = []
    paragraphOpeningDelimitation = { metaType: 'paragraphBreak' }

    for x in tokens

      if x.metaType is 'regular'
        if x.paragraph is 'opener'
          tokenSequence.push(paragraphOpeningDelimitation) # a bit superfluous right now
                                                           # or just lame doing it here

      tokenSequence.push(x)      

    util.timelog 'pickling'
    tokenSequenceSerialized = JSON.stringify(tokenSequence)
    util.timelog 'pickling'
    console.log """#{tokens.length} tokens pickled into #{tokenSequenceSerialized.length} long bytes stream"""
    console.log """pickled size to tokens ratio: #{parseFloat(tokenSequenceSerialized.length)/tokens.length}"""

    res.end(tokenSequenceSerialized)

    util.timelog """handling client ajax request for #{req.session.name}"""

    #
    # Persist the tokens for reuse
    #
    console.log 'saving tokens to data store' 
    storage.store 'tokens', req.session.name, tokenSequenceSerialized, req.session.docLogger

    req.session.tokenSequenceSerialized = tokenSequenceSerialized



