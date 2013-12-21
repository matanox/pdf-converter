#
# This creates the client library that needs to be served
# to the client for it to be able to use primus.
#
# See https://github.com/primus/primus#getting-started for more details
#

'use strict'

out = __dirname + '/public/javascripts' + '/primusClientLib.js'
console.log('Building primus client library to be served to the client as ' + out)

http = require("http")
Primus = require('primus')

server = require('http').createServer()
primus = new Primus(server, { transformer: 'websockets' });
primus.library();
primus.save(out)
