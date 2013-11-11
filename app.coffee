# Get own config
fs = require("fs")
nconf = require("nconf")
nconf.argv().env()
nconf.defaults host: "localhost"
host = nconf.get("host")

#
# Express Module dependencies.
#

express = require("express")
routes = require("./routes")
user = require("./routes/user")
http = require("http")
path = require("path")
app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.set "views", __dirname + "/views"
app.set "view engine", "ejs"
app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser("your secret here")
app.use express.session()
app.use app.router
app.use require("stylus").middleware(__dirname + "/public")
app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler() if "development" is app.get("env")
app.get "/", routes.index
app.get "/users", user.list
http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

passport = require("passport")
GoogleStrategy = require("passport-google").Strategy
passport.use new GoogleStrategy(
  #returnURL: "http://localhost:3000/auth/google/return"
  returnURL: "http://" + host + "/auth/google/return"
  realm: "http://" + host + "/auth/google",
 (identifier, profile, done) ->
  User.findOrCreate
    openId: identifier,
    (err, user) ->
    done err, user

)

# Redirect the user to Google for authentication.  When complete, Google
# will redirect the user back to the application at
#     /auth/google/return
app.get "/auth/google", passport.authenticate("google")

# Google will redirect the user to this URL after authentication.  Finish
# the process by verifying the assertion.  If valid, the user will be
# logged in.  Otherwise, authentication has failed.
app.get "/auth/google/return", passport.authenticate("google",
  successRedirect: "/landing.html"
  failureRedirect: "/login"
)
