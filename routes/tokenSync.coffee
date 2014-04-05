util    = require '../util'
logging = require '../logging' 
css     = require '../css'
storage = require '../storage'
require 'stream'
riak    = require('riak-js').getClient({host: "localhost", port: "8098"})
extract = require './extract'

exports.go = (req, res) ->
  #unless req.session.tokens? then return # replace with further error handling and logging here
  util.timelog """handling client ajax request for #{req.session.name}"""

  #
  # Handle get request
  #
  if Object.keys(req.body).length is 0
 

    if req.query.regenerate?
      docLogger = util.initDocLogger(baseFileName)
      generateFromHtml(req, req.session.name, res ,docLogger) 

    # unless the token sequence was retreived from the data store
    if req.session.tokenSequenceSerialized? 
      console.log 'serving tokens from cache'
      console.log req.session.tokenSequenceSerialized.length
      console.log typeof req.session.tokenSequenceSerialized
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

  #
  # Handle post request
  #
  else
    console.log """ajax request body length is #{req.body.length}"""
    tokenSequence = req.body # express.js (or rather it's bodyParser module) automatically turns the posted string into an object
                             # couldn't find yet how to avoid that...

    console.log 'received updated tokens from client' 
    util.timelog 'saving updated tokens to data store' 

    removed = 0
    filtered = []    
    #
    # Remove tokens marked for removal by user
    #
    for t in [0..tokenSequence.length-1] 
      if tokenSequence[t].remove
        removed += 1
      else 
        filtered.push tokenSequence[t]

    tokenSequence = filtered


    console.log """removed #{removed} tokens marked for removal by client request"""

    util.timelog 'pickling'
    tokenSequenceSerialized = JSON.stringify(tokenSequence)
    util.timelog 'pickling'

    storage.store 'tokens', req.session.name, tokenSequenceSerialized, req.session.docLogger
    util.timelog 'saving updated tokens to data store' 

    req.session.tokenSequenceSerialized = tokenSequenceSerialized        
    req.session.tokens = tokenSequence

    res.end('success') 
