#
# Express request error handler, 
# to include details of the request that the error was thrown for,
# along with the information of the error thrown in the code,
# and finally, send a suitable (error) response to the requesting client.
#
# (for guidance about express error handling, see http://expressjs.com/guide.html#error-handling)
#

logging = require './util/logging' 

exports.errorHandler = (error, request, response, next) ->
  console.error 'Error thrown for request: ' + request.url

  if error.stack?
    etext = error.stack
  else
    etext = error

  console.error(etext)

  logging.log('Sending error message to client')
  response.send(500, { error: error })  # no need to invoke 'next()', if we close off a response here.
