#
# The service definition and bootstrap - 
# quite a bag of code inline with express.js tradition
# now working as a node.js cluster 
#
# See - http://nodejs.org/api/cluster.html#cluster_how_it_works
#
# Note: given the forked type of node.js clustering, 
#       don't execute too much stuff before forking, 
#       to avoid unintended duplication of memory
#       and pointers to shared resources
#

'use strict'

#
# Get some configuration - using nconf for forward flexibility
#
fs = require('fs')
nconf = require('nconf')
nconf.argv().env().file({file: 'loggingConf.json'})
nconf.defaults 
  host: 'localhost'
  env:  'development'

#
# Express module dependencies
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
env = nconf.get 'env' # previously express app.get

# Node.js cluster modules
cluster = require('cluster');
numCPUs = require('os').cpus().length;

#
# Spawn cluster workers
#
spawnClusterWorkers = () ->
  workers = 2
  logging.logGreen """#{numCPUs} CPUs detected on host"""
  logging.logGreen """Spawning #{workers} cluster workers..."""

  firstFork = true # for doing something on on the first fork only
  for cpu in [1..workers]
    cluster.fork()

  cluster.on('listening', (worker, address) -> 
  # In dev mode, self-test on startup, just once
    logging.logGreen """Cluster worker #{worker.id} now sharing on #{address.address}:#{address.port} (pid #{worker.process.pid})"""
    selfMonitor = require('./selfMonitor').start('worker ' + worker.id)    
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

      # fire self test only for self cluster worker coming to life
      if firstFork
        firstFork = false
        testUrl = 'http://localhost' + ':' + port + '/handleInputFile?localLocation=' + testFile + '&runID=none'
        #testUrl = 'http://localhost' + ':' + app.get('port') + '/tokenSync' + '?regenerate=true'
        http.get(testUrl, (res) ->
          logging.logBlue 'Cluster response to its own synthetic client is: ' + res.statusCode)
  ) 

  cluster.on('exit', (worker, code, signal) -> 
    logging.logRed """Cluster worker #{worker.id} exited (pid #{worker.process.pid})"""
  )

#
# Start cluster master and cluster workers
#
if cluster.isMaster

  logging.logGreen "Local cluster starting in mode #{env}"
  logging.logGreen 'Using hostname ' + nconf.get('host')
  logging.logGreen 'Using port ' + port
  spawnClusterWorkers()
  selfMonitor = require('./selfMonitor').start('master')    

else

  #
  # Configure and start express
  #
  logging.init()
  app = express()
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

  #
  # Dev-environment-only stuff
  #
  unless env is 'production'
    primus = require './primus/primus' 
    # Attach primus for development iterating, as long as it's convenient 
    # primus.start(server)

  startServer = () ->
    #
    # Start the server
    #
    server = http.createServer(app)
    server.timeout = 0
    server.listen app.get('port') # , -> logging.logGreen 'cluster worker listening on port ' + app.get('port') + '....'

  startServer()
