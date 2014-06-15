#
# For rapid development - automatic client-side refresh during development
#

'use strict'
logging = require './logging' 

#
# Primus is an abstraction layer on top all prominent websocket implementation libraries.
# It is used here as a heuristic to automatically recycle any browser tabs that are already
# showing a page where the primus client is up (https://github.com/primus/primus#connecting-from-the-browser).
#
# It would also well be a candidate for use for real time bidrectional signaling and communication
# https://github.com/primus/primus
#

Primus = require('primus')

exports.start = (server) -> 
  primus = new Primus(server, { transformer: 'websockets' })

  sparks = 0
  logSpark = (spark, message) -> 
    sparksCount = sparks + ' ' + 'active sparks'
    logging.log('Primus: ' + spark.address.ip + ' (id ' + spark.id + ') ' + message + ' ' + '[' + sparksCount + ']')

  setTimeout((() -> 
  	unless sparks is 0
      logging.log('Primus: broadcasting \'up\' message to all quick to connect clients')
      primus.write("ServerRestarted")), 
    2000)

  primus.on('connection', (spark) -> # sparks are just the primus connection handles...
    sparks += 1
    logSpark(spark, 'connected on port ' + spark.address.port))

  primus.on('disconnection', (spark) ->
    sparks -= 1
    logSpark(spark, 'disconnected'))
