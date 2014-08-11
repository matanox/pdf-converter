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

logging = require './util/logging' 

# Get-or-default basic networking config
host = nconf.get 'host'
port = process.env.PORT or 3080

# Node.js cluster stuff
cluster = require('cluster');
numCPUs = require('os').cpus().length;

forkClusterWorkers = () ->
  logging.logGreen """#{numCPUs} CPUs detected on host"""
  workers = numCPUs
  logging.logGreen """Spawn #{workers} cluster workers..."""
  for cpu in [1..workers]
    cluster.fork()

  firstFork = true

  cluster.on('listening', (worker, address) -> 
  # In dev mode, self-test on startup, just once
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
      #testFile = 'Can Nature Make Us More Caring'    
      #testFile = 'wauthier13'    
      #testFile = 'xt7duLM0Q3Ow2gIBOvED'    
      testFile = 'gender differences 2013'    
      logging.logGreen """node.js cluster worker #{worker.id} now sharing on cluster listening port (pid #{worker.process.pid})"""

      # fire self test only for self cluster worker coming to life
      if firstFork
        firstFork = false
        testUrl = 'http://localhost' + ':' + port + '/handleInputFile?localLocation=' + testFile
        #testUrl = 'http://localhost' + ':' + app.get('port') + '/tokenSync' + '?regenerate=true'
        http.get(testUrl, (res) ->
          logging.logBlue 'Cluster response to its own synthetic client is: ' + res.statusCode)
  ) 

  cluster.on('exit', (worker, code, signal) -> 
    logging.logRed """node.js cluster worker #{worker.id} exited (pid #{worker.process.pid})"""
  )

if cluster.isMaster
  logging.logGreen "Local cluster starting in mode #{env}"
  logging.logGreen 'Using hostname ' + nconf.get('host')
  logging.logGreen 'Using port ' + port
  forkClusterWorkers()

else

  #
  # Configure and start express
  #
  app = express()
  env = app.get('env')

  logging.init()

  #
  # Dev-environment-only stuff
  #
  unless env is 'production'
    primus = require './primus/primus' 

  app.set 'port', port

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

  app.get '/handleInputFile', require('../src/core/handleInputFile').go

  startServer = () ->
    #
    # Start the server
    #
    server = http.createServer(app)

    server.timeout = 0

    server.listen app.get('port'), ->
      logging.logGreen 'cluster worker listening on port ' + app.get('port') + '....'

    # Attach primus for development iterating, as long as it's convenient 
    # unless env is 'production' then primus.start(server)

  startServer()

  selfMonitor = require('./selfMonitor').start()
