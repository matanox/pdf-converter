#
# The service definition and bootstrap - 
# quite a bag of code inline with express.js tradition
#

'use strict'

# Get config (as much as it overides defaults)
fs = require('fs')
nconf = require('nconf')
nconf.argv().env().file({file: 'loggingConf.json'})
nconf.defaults host: 'localhost'

#
# Express module dependencies.
#
express = require 'express'
routes  = require '../routes'
http    = require 'http'
path    = require 'path'

# Regular module dependencies
errorHandling = require './errorHandling'
authorization = require './authorization'
logging       = require './util/logging' 
#convert       = require './routes/convert'
#extract       = require './routes/extract'
#markers       = require './markers'
#fluff         = require './metaFluff'

#
# Configure and start express
#
app = express()
env = app.get('env')

logging.init()
logging.logGreen "Starting in mode #{env}"

logging.log('Starting in mode ' + env) 

#
# Dev-environment-only stuff
#
unless env is 'production'
  primus = require './primus/primus' 

# Get-or-default basic networking config
host = nconf.get 'host'
logging.logGreen 'Using hostname ' + nconf.get('host')
app.set 'port', process.env.PORT or 3080
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
#app.use express.multipart()
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
#app.get '/', routes.index
#app.get '/users', user.list

app.get '/handleInputFile', require('../src/core/handleInputFile').go
#app.get  '/tokenSync', require('./routes/tokenSync').go
#app.post '/tokenSync', require('./routes/tokenSync').go

#app.get '/serveIntermediaryFile', require('./routes/serveIntermediaryFile').go
#app.get '/convert', convert.go
#app.get '/extract', extract.go

#
# Authorization
#
#authorization.googleAuthSetup(app, host, routes)

startServer = () ->
  #
  # Start the server
  #
  server = http.createServer(app)

  server.timeout = 0

  server.listen app.get('port'), ->
    logging.logGreen 'Server listening on port ' + app.get('port') + '....'

  
  # In dev mode, self-test on startup
  unless env is 'production' 
    #testFile = 'AzPP5D8IS0GDeeC1hFxs'
    #testFile = 'xt7duLM0Q3Ow2gIBOvED'
    #testFile = 'leZrsgpZQOSCCtS98bsu'
    #testUrl = 'http://localhost/extract?name=' + testFile
    #testFile = 'S7VUdDeES5O6Xby6xtc7'
    #testFile = 'LaeUusATIi5FHXHmF4hU'    # 'rwUEzeLnRfKgNh23R82W'
    #testFile = 'To%20Belong%20or%20Not%20to%20Belong,%20That%20Is%20the%20Question'    
    #testFile = 'To Belong or Not to Belong,%20That%20Is%20the%20Question'    
    #testFile = 'wauthier13'    
    #testFile = '0h6yIy8ITd6gQdc1XDb4'    
    testFile = 'wauthier13'    

    testUrl = 'http://localhost' + ':' + app.get('port') + '/handleInputFile?localLocation=' + testFile
    #testUrl = 'http://localhost' + ':' + app.get('port') + '/tokenSync' + '?regenerate=true'
    http.get(testUrl, (res) ->
      logging.logBlue 'Server response to its own synthetic client is: ' + res.statusCode)

  # Attach primus for development iterating, as long as it's convenient 
  # unless env is 'production' then primus.start(server)

startServer()

selfMonitor = require('./selfMonitor').start()
