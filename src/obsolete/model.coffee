#
# Old take at object orienting the tokens... not that critical
#

util = require('./util/util')
logging = require './util/logging' 

# Class Description: 
# This can be a word, punctuation mark (or much more rarely) a superscript reference or note.
class Token
  
  # Allowed types definition. Not making each type a separate class for now.
  types = ['word',
           'punctuation,'
           'superscriptComment']

  constructor: (type, content) ->
    unless util.isAnyOf(type, types)
      util.objectViolation('invalid token type encountered on token creation')
    @type    = type
    @content = content
    @partOf  = [] # links to TokenGroups that it will belong to
      
# Class Description:
# This is a group of tokens, or a group of groups of tokens.
class TokenGroup 
  # TODO: add avoiding a group including itself
  # Allowed types definition. Not making each type a separate class for now.
  types = ['section',
           'heading',
           'sentence',
           'paragraph',
           'list',
           'title']

  constructor: () ->
    @has    = [] # Tokens or TokenGroups that is will have
    @partOf = [] # links to TokenGroups that it will belong to

  add: (token) ->
    unless token instanceof Token or token instanceof TokenGroup
      util.objectViolation('TokenGroup can only include Token or TokenGroup objects')
    @has.push(token)

  getAll: ->
    @has

  setType: (type) ->
    util.objectViolation('cannot assign invalid TokenGroup type to TokenGroup') unless util.isAnyOf(type, types) 
    @type = type 

  getType: () ->
    @type

###

Move to unit tests stuff like this:

t = new Token('word')
g = new TokenGroup
g.add(t)
g.add(g)
logging.log(g.getType())
g.setType("sentence")
logging.log(g.getType())
logging.log(g.getAll())
logging.log('done')
###