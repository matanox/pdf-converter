'use strict'

# Get config (as much as it overides defaults)
fs = require('fs')
nconf = require('nconf')
nconf.argv().env()
nconf.defaults host: 'localhost'

#
# Express module dependencies.
#
express = require 'express'
routes  = require './routes'
http    = require 'http'
path    = require 'path'
user    = require './routes/user'

# Regular module dependencies
convert       = require './routes/convert'
extract       = require './routes/extract'
errorHandling = require './errorHandling'
authorization = require './authorization'
logging       = require './logging' 
markers       = require './markers'

#
# Configure and start express
#
app = express()
env = app.get('env')

logging.logGreen "Starting in mode #{env}"

#
# Dev-environment-only stuff
#
unless env is 'production'
  primus = require './primus' 

# Get-or-default basic networking config
host = nconf.get 'host'
logging.logGreen 'Using hostname ' + nconf.get('host')
app.set 'port', process.env.PORT or 80
logging.logGreen 'Using port ' + app.get('port')

#
# Configure express middlewares. Order DOES matter.
#
app.set 'views', __dirname + '/views'
app.set 'view engine', 'ejs'
app.use express.favicon()

# Setup the connect.js logger used by express.js
# See http://www.senchalabs.org/connect/logger.html for configuration options.
# (specific logging info and colors can be configured if custom settings are not enough)
if env is 'production'
  app.use express.logger('default')    # This would be verbose enough for production
else 
  app.use express.logger('dev')        # dev is colorful (for a terminal) and not overly verbose

app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser('93AAAE3G205OI33')
app.use express.session()
app.use app.router
#app.use require('stylus').middleware(__dirname + '/public')
app.use express.static(path.join(__dirname, 'public'))

app.use errorHandling.errorHandler
#app.use express.errorHandler() if env is 'production' # TODO: test if this is better than my own.

#
# Setup some routing
#
app.get '/', routes.index
app.get '/users', user.list
app.get '/convert', convert.go
app.get '/extract', extract.go

#
# Authorization
#
authorization.googleAuthSetup(app, host, routes)

startServer = () ->
  #
  # Start the server
  #
  server = http.createServer(app)

  server.listen app.get('port'), ->
    logging.logGreen 'Server listening on port ' + app.get('port') + '....'

  ###
  # In dev mode, self-test on startup
  unless env is 'production' 
    #testFile = 'AzPP5D8IS0GDeeC1hFxs'
    testFile = 'leZrsgpZQOSCCtS98bsu'
    http.get('http://localhost/extract?name=' + testFile, (res) -> # xt7duLM0Q3Ow2gIBOvED
      logging.logBlue 'Server response to its own synthetic client is: ' + res.statusCode)

  # Attach primus for development iterating, as long as it's convenient 
  unless env is 'production' then primus.start(server)
  ###

#
# Get data that can apply to any document
#

markers.load(startServer)

selfMonitor = require('./selfMonitor').start()

winston = require 'winston'
exports.winston = winston

require('winston-logstash')
winston.add(winston.transports.Logstash, {port: 28777, node_name: 'nodejs', host: '127.0.0.1'})



sub = {sub: 'sub'}
logSample = {a: '3', b: 'bbbb', sub}
winston.log('warn', logSample)
#winston.log('warn', 'Hello to logstash')

testLogio = () ->
  require 'winston-logio' 
  winston.add(winston.transports.Logio, {
      port: 28777,
      node_name: 'nodejs',
      host: '127.0.0.1'
    });
 
  winston.log('info', 'Hello to logio')

testGraylog2 = () ->
  winston.add(require('winston-graylog2').Graylog2, {})
  winston.log('info', 'Hello to graylog2')
