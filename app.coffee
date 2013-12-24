'use strict'

# Get config (as much as it overides defaults)
fs = require('fs')
nconf = require('nconf')
nconf.argv().env()
nconf.defaults host: 'localhost'

#
# Express Module dependencies.
#
express = require 'express'
routes  = require './routes'
user    = require './routes/user'
convert = require './routes/convert'
extract = require './routes/extract'
http    = require 'http'
path    = require 'path'

#
# Configure and start express
#

app = express()
env = app.get('env')
console.log('starting in mode ' + env)

unless env is 'production'
  #
  # Dev environment stuff
  #
  require 'coffee-trace'
  primus = require './primus' 

# Handle basic networkign config
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

#app.use express.directory(__dirname + '/outputTemplate')
#app.use express.static(path.join(__dirname, 'outputTemplate'))

app.use express.errorHandler() unless app.get('env') is 'production'
app.get '/', routes.index
app.get '/users', user.list
app.get '/convert', convert.go
app.get '/extract', extract.go

# 
# This won't work on a non public DNS server, 
# such as a local dev server, as:
#
# a server needs to be installed out on the Internet (e.g. Heroku) 
# in order for Google to be able to complete the authnetication flow, 
# as the later finishes off in getting back to our web server via public DNS!
#
googleAuthSetup = () ->
  passport = require('passport')
  GoogleStrategy = require('passport-google').Strategy
  passport.use new GoogleStrategy(
    #returnURL: 'http://localhost:3000/auth/google/return'
    returnURL: 'http://' + host + '/auth/google/return'
    realm: 'http://' + host + '/auth/google',
    (identifier, profile, done) ->
      console.log 'authorized user ' + identifier + '\n' + JSON.stringify(profile))
      #User.findOrCreate
      #  openId: identifier,
      #  (err, user) ->
      #  done err, user

  # Redirect the user to Google for authentication.  When complete, Google
  # will redirect the user back to the application at /auth/google/return
  app.get '/auth/google', passport.authenticate('google')

  # Google will redirect the user to this URL after authentication.  Finish
  # the process by verifying the assertion.  If valid, the user will be
  # logged in.  Otherwise, authentication has failed.
  app.get '/auth/google/return', routes.index

  #app.get '/auth/google/return', passport.authenticate('google',
  #  successRedirect: '/'
  #  failureRedirect: '/'
  #)
  true

googleAuthSetup

server = http.createServer(app)

server.listen app.get('port'), ->
  console.log 'Server listening on port ' + app.get('port')

http.get('http://localhost/extract?name=leZrsgpZQOSCCtS98bsu', (res) -> # xt7duLM0Q3Ow2gIBOvED
  console.log('server response is: ' + res.statusCode))

# Attach primus for development iterating, as long as it's convenient 
unless env is 'production' then primus.start(server)
