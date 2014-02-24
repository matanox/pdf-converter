util    = require '../util'
logging = require '../logging' 
css     = require '../css'


exports.go = (req, res) ->
  unless req.session.tokens then return # replace with further error handling and logging here

  tokenSequence = []
  paragraphOpeningDelimitation = { metaType: 'paragraphBreak' }

  for x in req.session.tokens 

    if x.metaType is 'regular'
      if x.paragraph is 'opener'
        tokenSequence.push(paragraphOpeningDelimitation)

    tokenSequence.push(x)      

  res.json(tokenSequence)