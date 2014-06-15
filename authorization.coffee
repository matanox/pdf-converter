#
# Google authentication, hopefully this still works without necessary changes
# should scale to also facebook (and others)
#

logging = require './logging' 
# 
# This won't work on a non public DNS server, 
# such as a local dev server, as:
#
# a server needs to be installed out on the Internet (e.g. Heroku) 
# in order for Google to be able to complete the authnetication flow, 
# as the later finishes off in getting back to our web server via public DNS!
#
exports.googleAuthSetup = (app, host, routes) ->
  passport = require('passport')
  GoogleStrategy = require('passport-google').Strategy
  passport.use new GoogleStrategy(
    #returnURL: 'http://localhost:3000/auth/google/return'
    returnURL: 'http://' + host + '/auth/google/return'
    realm: 'http://' + host + '/auth/google',
    (identifier, profile, done) ->
      logging.log 'authorized user ' + identifier + '\n' + JSON.stringify(profile))
      #User.findOrCreate
      #  openId: identifier,
      #  (err, user) ->
      #  done err, user

  # Redirect the user to Google for authentication.  When complete, Google
  # will redirect the user back to the application at /auth/google/return
  app.get '/auth/google', passport.authenticate('google')

  # Google will redirect the user to this URL after authentication.  Finish
  # the process by verifying the assertion.  If valid, the user will be
  # logged in. Otherwise, authentication has failed.
  app.get '/auth/google/return', routes.index

  #app.get '/auth/google/return', passport.authenticate('google',
  #  successRedirect: '/'
  #  failureRedirect: '/')
  true
