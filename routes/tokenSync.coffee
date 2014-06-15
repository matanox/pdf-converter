#
# Syncronizes text tokens with the client - 
# both delivering tokens for a processed input pdf, 
# and updating the tokens after they were changed by the user
#

util    = require '../util'
logging = require '../logging' 
css     = require '../css'
storage = require '../storage'
require 'stream'
riak    = require('riak-js').getClient({host: "localhost", port: "8098"})
extract = require './extract'
Sync    = require 'sync'

serveTokens = (req, res) ->
  if req.session.serializedTokens?
    serializedTokens = req.session.serializedTokens
  else
    util.timelog 'pickling'
    serializedTokens = JSON.stringify(req.session.tokens)
    console.log """#{req.session.tokens.length} tokens pickled into #{serializedTokens.length} long bytes stream"""
    console.log """pickled size to tokens ratio: #{parseFloat(serializedTokens.length)/req.session.tokens.length}"""
    util.timelog 'pickling'

    #
    # Persist the tokens for reuse - in both DB and session
    #
    console.log 'saving tokens to data store' 
    storage.store 'tokens', req.session.name, serializedTokens, req.session.docLogger
    req.session.serializedTokens = serializedTokens

  ###
  tokens = []
  paragraphOpeningDelimitation = { metaType: 'paragraphBreak' }
  for x in req.session.tokens 
    if x.metaType is 'regular'
      if x.paragraph is 'opener'
        tokens.push(paragraphOpeningDelimitation) # a bit superfluous right now
                                                         # or just lame doing it here
    tokens.push(x)      
  ###
  res.end(serializedTokens)

exports.go = (req, res) ->
  #unless req.session.tokens? then return # replace with further error handling and logging here
  util.timelog """handling client ajax request for #{req.session.name}"""

  #
  # Handling a get request
  #
  if Object.keys(req.body).length is 0
 
    #
    # regenerate tokens by server, if requested
    #
    if req.query.regenerate? or (not req.session.serializedTokens?)
      console.log 'generating tokens'
      
      # hack for self testing on startup
      unless req.session.name?
        req.session.name = 'LaeUusATIi5FHXHmF4hU'

      docLogger = util.initDocLogger(req.session.name)
      extract.generateFromHtml(req, req.session.name, res ,docLogger, () -> serveTokens(req, res)) 
      
    else
      serveTokens(req, res)        
      #if req.session.tokens? 
        #console.log 'serving existing tokens'
        #console.log req.session.serializedTokens.length
        #console.log typeof req.session.serializedTokens

        #res.end(req.session.serializedTokens)     

  #
  # Handling a post request
  #
  else
    console.log """ajax request body length is #{req.body.length}"""
    tokens = req.body # express.js (or rather it's bodyParser module) automatically turns the posted string into an object
                             # couldn't find yet how to avoid that...

    console.log 'received updated tokens from client' 
    util.timelog 'saving updated tokens to data store' 

    removed = 0
    filtered = []    
    #
    # Remove tokens marked for removal by user
    #
    for t in [0..tokens.length-1] 
      if tokens[t].remove
        removed += 1
      else 
        filtered.push tokens[t]

    tokens = filtered


    console.log """removed #{removed} tokens marked for removal by client request"""

    util.timelog 'pickling'
    serializedTokens = JSON.stringify(tokens)
    util.timelog 'pickling'

    storage.store 'tokens', req.session.name, serializedTokens, req.session.docLogger
    util.timelog 'saving updated tokens to data store' 

    req.session.serializedTokens = serializedTokens        
    req.session.tokens = tokens

    res.end('success') 
