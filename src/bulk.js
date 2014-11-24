// Generated by CoffeeScript 1.6.3
var aggregateRequestsWait, batchRunID, directory, filename, flood, fs, host, http, i, logging, makeRequest, maxFiles, nconf, parallelism, port, rdbms, requests, responses, toRequest, util, _i, _j, _k, _len, _len1, _ref;

http = require('http');

fs = require('fs');

nconf = require('nconf');

util = require('./util/util');

logging = require('./util/logging');

rdbms = require('./storage/rdbms/rdbms');

nconf.argv().env();

nconf.defaults({
  host: "localhost",
  directory: '../data/pdf/0-input/',
  flood: false,
  parallelism: 2,
  maxFiles: process.argv[2] || 10000
});

host = nconf.get('host');

port = process.env.PORT || 3080;

logging.logGreen("Connecting to hostname " + (nconf.get('host')) + ", port " + port);

directory = nconf.get('directory');

logging.logGreen('Invoking over input files from ' + util.terminalClickableFileLink(directory));

flood = nconf.get('flood');

switch (flood) {
  case true:
    logging.logPerf('Running in flood mode');
    break;
  case false:
    logging.logPerf('Running in controlled load mode');
    break;
  default:
    logging.logYellow('Invalid value for the flood argument');
    process.exit(0);
}

parallelism = nconf.get('parallelism');

logging.logPerf("Degree of parallelism: " + parallelism);

maxFiles = nconf.get('maxFiles');

logging.logGreen('');

batchRunID = util.simpleGenerateRunID();

logging.logGreen('Using run ID ' + batchRunID);

rdbms.write(null, 'runIDs', {
  runID: batchRunID
});

http.globalAgent.maxSockets = 1000;

requests = 0;

responses = 0;

aggregateRequestsWait = 0;

makeRequest = function(filename) {
  var httpCallBack;
  requests += 1;
  httpCallBack = (function(filename) {
    return function(res) {
      var responseBody;
      responses += 1;
      responseBody = '';
      res.on('data', function(chunk) {
        return responseBody += chunk;
      });
      return res.on('end', function() {
        var overall, requestElapsedTime;
        if (res.statusCode === 200) {
          logging.logGreen('Server response for ' + filename + ' is:   ' + res.statusCode);
          rdbms.write(null, 'runs', {
            docName: filename.replace('.pdf', ''),
            runID: batchRunID,
            status: 'success'
          });
        } else {
          logging.logYellow('Server response for ' + filename + ' is:   ' + res.statusCode + ', ' + responseBody);
          rdbms.write(null, 'runs', {
            docName: filename.replace('.pdf', ''),
            runID: batchRunID,
            status: 'failed',
            statusDetail: responseBody
          });
        }
        if (!flood) {
          if (toRequest.length > 0) {
            makeRequest(toRequest.shift());
          }
        }
        console.log(responses + ' responses out of ' + requests + ' requests received thus far');
        requestElapsedTime = util.timelog(null, 'Server response for ' + filename);
        aggregateRequestsWait += requestElapsedTime;
        if (responses === requests) {
          overall = util.timelog(null, 'Overall');
          logging.logPerf('');
          logging.logPerf(' Timing:');
          logging.logPerf('');
          logging.logPerf(' elapsed   ' + overall / 1000 + ' secs');
          logging.logPerf(' averaged  ' + overall / 1000 / responses + ' (sec/request)');
          logging.logPerf(' wait time ' + aggregateRequestsWait / 1000 + ' secs (typically more than elapsed time)');
          logging.logPerf(' averaged  ' + aggregateRequestsWait / 1000 / responses + ' (sec/request)');
          logging.logPerf('');
          logging.logPerf(" Parallelism degree employed was " + parallelism);
          logging.logPerf('');
          setTimeout((function() {
            return process.exit(0);
          }), 3000);
        }
      });
    };
  })(filename);
  console.log("Requesting " + filename);
  util.timelog(null, 'Server response for ' + filename);
  return http.get({
    host: host,
    port: port,
    path: '/handleInputFile?' + 'localLocation=' + encodeURIComponent(filename) + '&runID=' + batchRunID,
    method: 'GET'
  }, httpCallBack).on('error', function(e) {
    return console.log("Got error: " + e.message);
  });
};

util.timelog(null, 'Overall');

toRequest = [];

_ref = fs.readdirSync(directory);
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  filename = _ref[_i];
  if (fs.statSync(directory + filename).isFile()) {
    if (filename !== '.gitignore') {
      if (toRequest.length < maxFiles) {
        toRequest.push(directory + filename);
      }
    } else {
      console.log('Skipping .gitignore');
    }
  } else {
    console.log('Skipping subdirectory ' + filename);
  }
}

if (toRequest.length > 0) {
  if (!flood) {
    if (parallelism > toRequest.length) {
      logging.logYellow('Note: specified degree of parallelism is greater than number of files to process');
      parallelism = toRequest.length;
    }
    for (i = _j = 1; 1 <= parallelism ? _j <= parallelism : _j >= parallelism; i = 1 <= parallelism ? ++_j : --_j) {
      if (toRequest.length > 0) {
        makeRequest(toRequest.shift());
      }
    }
  } else {
    for (_k = 0, _len1 = toRequest.length; _k < _len1; _k++) {
      filename = toRequest[_k];
      makeRequest(filename);
    }
  }
} else {
  logging.logYellow('No files to process in directory. Existing.');
}
