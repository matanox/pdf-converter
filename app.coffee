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

#
# Configure and start express
#
app = express()
env = app.get('env')
console.log('starting in mode ' + env)

#
# Dev-environment-only stuff
#
unless env is 'production'
  primus = require './primus' 

# Get-or-default basic networking config
host = nconf.get 'host'
console.log 'using hostname ' + nconf.get('host')
app.set 'port', process.env.PORT or 80
console.log('using port ' + app.get('port'))

# Now down to business
app.set 'views', __dirname + '/views'
app.set 'view engine', 'ejs'
app.use express.favicon()
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser('93AAAE3G205OI33')
app.use express.session()
app.use app.router
#app.use require('stylus').middleware(__dirname + '/public')
app.use express.static(path.join(__dirname, 'public'))
app.use errorHandling.errorHandler

#app.use express.directory(__dirname + '/outputTemplate')
#app.use express.static(path.join(__dirname, 'outputTemplate'))

app.use express.errorHandler() unless app.get('env') is 'production'
app.get '/', routes.index
app.get '/users', user.list
app.get '/convert', convert.go
app.get '/extract', extract.go

authorization.googleAuthSetup(app, host, routes)

server = http.createServer(app)

server.listen app.get('port'), ->
  console.log 'Server listening on port ' + app.get('port')

http.get('http://localhost/extract?name=leZrsgpZQOSCCtS98bsu', (res) -> # xt7duLM0Q3Ow2gIBOvED
  console.log('server response is: ' + res.statusCode))

# Attach primus for development iterating, as long as it's convenient 
unless env is 'production' then primus.start(server)
