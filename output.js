// Generated by CoffeeScript 1.6.3
var fs, hookElementTextPos, hookId, logging, outputTemplate, util;

util = require('./util');

logging = require('./logging');

fs = require('fs');

outputTemplate = fs.readFileSync('outputTemplate/template.html').toString();

hookId = 'hookPoint';

hookElementTextPos = outputTemplate.indexOf(">", outputTemplate.indexOf('id="' + hookId + '"')) + 1;

exports.serveOutput = function(html, name, res, docLogger) {
  var outputFile;
  outputFile = '../local-copies/' + 'output/' + name + '.html';
  util.timelog('Saving serialized output to file');
  return fs.writeFile(outputFile, outputHtml, function(err) {
    if (err != null) {
      res.send(500);
      throw err;
    }
    util.timelog('Saving serialized output to file', docLogger);
    docLogger.info('Sending response....');
    util.timelog('from upload to serving', docLogger);
    return res.sendfile(name + '.html', {
      root: '../local-copies/' + 'output/'
    });
  });
};
