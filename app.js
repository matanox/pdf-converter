// Generated by CoffeeScript 1.6.3
'use strict';
var app, authorization, env, errorHandling, express, fs, host, http, logging, nconf, path, primus, routes, selfMonitor, startServer;

fs = require('fs');

nconf = require('nconf');

nconf.argv().env().file({
  file: 'loggingConf.json'
});

nconf.defaults({
  host: 'localhost'
});

express = require('express');

routes = require('./routes');

http = require('http');

path = require('path');

errorHandling = require('./errorHandling');

authorization = require('./authorization');

logging = require('./logging');

app = express();

env = app.get('env');

logging.init();

logging.logGreen("Starting in mode " + env);

logging.log('Starting in mode ' + env);

if (env !== 'production') {
  primus = require('./primus');
}

host = nconf.get('host');

logging.logGreen('Using hostname ' + nconf.get('host'));

app.set('port', process.env.PORT || 3080);

logging.logGreen('Using port ' + app.get('port'));

app.set('views', __dirname + '/views');

app.set('view engine', 'ejs');

app.use(express.favicon());

if (env === 'production') {
  app.use(express.logger('default'));
} else {
  app.use(express.logger('dev'));
}

app.use(express.bodyParser());

app.use(express.methodOverride());

app.use(express.cookieParser('93AAAE3G205OI33'));

app.use(express.session());

app.use(app.router);

app.use(express["static"](path.join(__dirname, 'public')));

app.use(errorHandling.errorHandler);

app.get('/handleInputFile', require('./routes/handleInputFile').go);

startServer = function() {
  var server, testFile, testUrl;
  server = http.createServer(app);
  server.timeout = 0;
  server.listen(app.get('port'), function() {
    return logging.logGreen('Server listening on port ' + app.get('port') + '....');
  });
  if (env !== 'production') {
    testFile = 'agriculture3';
    testUrl = 'http://localhost' + ':' + app.get('port') + '/handleInputFile?localLocation=' + testFile;
    return http.get(testUrl, function(res) {
      return logging.logBlue('Server response to its own synthetic client is: ' + res.statusCode);
    });
  }
};

startServer();

selfMonitor = require('./selfMonitor').start();
