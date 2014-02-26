util    = require '../util'
logging = require '../logging' 
css     = require '../css'

exports.go = (req, res) ->
  unless req.session.tokens? then return # replace with further error handling and logging here

  tokens = JSON.parse(req.session.tokens) 

  tokenSequence = []
  paragraphOpeningDelimitation = { metaType: 'paragraphBreak' }

  for x in tokens

    if x.metaType is 'regular'
      if x.paragraph is 'opener'
        tokenSequence.push(paragraphOpeningDelimitation) # a bit superfluous right now
                                                         # or just lame doing it here

    tokenSequence.push(x)      

  tokenSequenceSerialized = JSON.stringify(tokenSequence)
  res.end(tokenSequenceSerialized)