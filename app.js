// Generated by CoffeeScript 1.4.0
'use strict';

var Primus, app, convert, express, extract, fs, googleAuthSetup, host, http, nconf, path, primus, routes, server, user;

fs = require("fs");

nconf = require("nconf");

nconf.argv().env();

nconf.defaults({
  host: "localhost"
});

host = nconf.get("host");

console.log("Host is " + nconf.get("host"));

express = require("express");

routes = require("./routes");

user = require("./routes/user");

convert = require("./routes/convert");

extract = require("./routes/extract");

http = require("http");

path = require("path");

app = express();

Primus = require('primus');

app.set("port", process.env.PORT || 80);

console.log("Port is " + app.get("port"));

app.set("views", __dirname + "/views");

app.set("view engine", "ejs");

app.use(express.favicon());

app.use(express.logger("dev"));

app.use(express.bodyParser());

app.use(express.methodOverride());

app.use(express.cookieParser("93ADEE3820567DB"));

app.use(express.session());

app.use(app.router);

app.use(express["static"](path.join(__dirname, "public")));

if ("development" === app.get("env")) {
  app.use(express.errorHandler());
}

app.get("/", routes.index);

app.get("/users", user.list);

app.get("/convert", convert.go);

app.get("/extract", extract.go);

googleAuthSetup = function() {
  var GoogleStrategy, passport;
  passport = require("passport");
  GoogleStrategy = require("passport-google").Strategy;
  passport.use(new GoogleStrategy({
    returnURL: "http://" + host + "/auth/google/return",
    realm: "http://" + host + "/auth/google"
  }, function(identifier, profile, done) {
    return console.log("authorized user " + identifier + "\n" + JSON.stringify(profile));
  }));
  app.get("/auth/google", passport.authenticate("google"));
  app.get("/auth/google/return", routes.index);
  return true;
};

googleAuthSetup;


server = http.createServer(app).listen(app.get("port"), function() {
  return console.log("Express server listening on port " + app.get("port"));
});

primus = new Primus(server, {
  transformer: 'websockets'
});

primus.on('connection', function(spark) {
  return console.log('New Primus connection established ' + 'from ' + spark.address + ' and given the id ' + spark.id);
});

http.get('http://localhost/extract?name=xt7duLM0Q3Ow2gIBOvED', function(res) {
  return console.log("server response is: " + res.statusCode);
});
