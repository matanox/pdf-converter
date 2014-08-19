// Generated by CoffeeScript 1.6.3
var convert, extract, fetch, fs, getFromUrl, logging, setOutFile, util, winston;

convert = require('./convert');

extract = require('./extract');

util = require('../util/util');

getFromUrl = require('request');

fs = require('fs');

winston = require('winston');

logging = require('../util/logging');

fetch = function(inkUrl, outFile, docLogger, req, res, callOnSuccess) {
  var download;
  return download = getFromUrl(inkUrl, function(error, response, body) {
    if (!error && response.statusCode === 200) {
      return callOnSuccess(outFile, docLogger, req, res);
    } else {
      console.log("fetching from InkFilepicker returned http status " + response.statusCode);
      if (error) {
        return docLogger.info("fetching from InkFilepicker returned error " + error);
      }
    }
  }).pipe(fs.createWriteStream(outFile));
};

setOutFile = function(baseFileName) {
  return "../local-copies/" + "pdf/" + baseFileName + ".pdf";
};

exports.go = function(req, res) {
  var baseFileName, context, docLogger, inkUrl, outFile;
  if (req.query.inkUrl != null) {
    inkUrl = req.query.inkUrl;
    baseFileName = inkUrl.replace('https://www.filepicker.io/api/file/', '');
    docLogger = util.initDocLogger(baseFileName);
    docLogger.info('logger started');
    req.session.docLogger = docLogger;
    outFile = setOutFile(baseFileName);
    fetch(inkUrl, outFile, docLogger, req, res, convert.go);
  }
  if (req.query.localLocation != null) {
    context = {
      runID: req.query.runID
    };
    baseFileName = req.query.localLocation.replace('.pdf', '');
    logging.logGreen("Started handling input file: " + baseFileName + ". Given run id is: " + context.runID);
    docLogger = util.initDocLogger(baseFileName);
    docLogger.info('logger started');
    outFile = setOutFile(baseFileName);
    return convert.go(context, outFile, docLogger, req, res);
  }
};
