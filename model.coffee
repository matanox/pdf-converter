util = require('./util')

# Class Description: 
# This can be a word, punctuation mark (or much more rarely) a superscript reference or note
class Token
  
  # Allowed types definition. Not making each type a separate class for now
  types = ['word',
           'punctuation,'
           'superscriptComment']

  constructor: (type) ->
    @type = type
    unless util.isAnyOf(@type, types)
      error = new Error('invalid token type encountered on token creation')
      console.log(error.stack)
      throw error

# Class Description:
# This is a group of tokens. 
class TokenGroup
  constructor: () ->
    @tokens = []

  add: (token) ->
    util.objectViolation('TokenGroup can only include Token objects') unless token instanceof Token
    @tokens.push(token)


  getAll: ->
  	@tokens

a = new Token('word')
b = new TokenGroup
b.add(a)
console.log(b)



