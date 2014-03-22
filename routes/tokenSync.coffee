util    = require '../util'
logging = require '../logging' 
css     = require '../css'

exports.go = (req, res) ->
  unless req.session.tokens? then return # replace with further error handling and logging here

  util.timelog """handling client ajax request for #{req.session.name}"""

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
