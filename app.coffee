'use strict'

# Get own config
fs = require("fs")
nconf = require("nconf")
nconf.argv().env()
nconf.defaults host: "localhost"
host = nconf.get "host"
console.log "Host is " + nconf.get("host")

#
# Express Module dependencies.
#

express = require("express")
routes = require("./routes")
user = require("./routes/user")
convert = require("./routes/convert")
extract = require("./routes/extract")
http = require("http")
path = require("path")

primus = require('./primus')

app = express()
app.set "port", process.env.PORT or 80
console.log("Port is " + app.get("port"))

app.set "views", __dirname + "/views"
app.set "view engine", "ejs"
app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser("93ADEE3820567DB")
app.use express.session()
app.use app.router
#app.use require("stylus").middleware(__dirname + "/public")
app.use express.static(path.join(__dirname, "public"))

#app.use express.directory(__dirname + '/outputTemplate')
#app.use express.static(path.join(__dirname, "outputTemplate"))

app.use express.errorHandler() unless app.get("env") is "production"
app.get "/", routes.index
app.get "/users", user.list
app.get "/convert", convert.go
app.get "/extract", extract.go

# Need to be installed out on the Internet (e.g. Heroku) for Google 
# being able to complete the authnetication flow, that culminates
# in getting back to our web server via public dns.
googleAuthSetup = () ->
  passport = require("passport")
  GoogleStrategy = require("passport-google").Strategy
  passport.use new GoogleStrategy(
    #returnURL: "http://localhost:3000/auth/google/return"
    returnURL: "http://" + host + "/auth/google/return"
    realm: "http://" + host + "/auth/google",
    (identifier, profile, done) ->
      console.log "authorized user " + identifier + "\n" + JSON.stringify(profile)
      #User.findOrCreate
      #  openId: identifier,
      #  (err, user) ->
      #  done err, user

  )

  # Redirect the user to Google for authentication.  When complete, Google
  # will redirect the user back to the application at /auth/google/return
  app.get "/auth/google", passport.authenticate("google")

  # Google will redirect the user to this URL after authentication.  Finish
  # the process by verifying the assertion.  If valid, the user will be
  # logged in.  Otherwise, authentication has failed.
  app.get "/auth/google/return", routes.index

  #app.get "/auth/google/return", passport.authenticate("google",
  #  successRedirect: "/"
  #  failureRedirect: "/"
  #)
  true

googleAuthSetup

server = http.createServer(app)

server.listen app.get("port"), ->
  console.log "Server listening on port " + app.get("port")

http.get('http://localhost/extract?name=leZrsgpZQOSCCtS98bsu', (res) -> # xt7duLM0Q3Ow2gIBOvED
  console.log("server response is: " + res.statusCode))

unless app.get("env") is "production" then primus.start(server)

