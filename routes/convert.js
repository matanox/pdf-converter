// Generated by CoffeeScript 1.6.3
var crypto, dataWriter, docMeta, exec, executable, executalbeParams, fs, logging, output, redirectToExtract, redirectToShowHtml, riak, storage, util;

util = require('../util');

logging = require('../logging');

docMeta = require('../docMeta');

storage = require('../storage');

require('stream');

exec = require("child_process").exec;

riak = require('riak-js').getClient({
  host: "localhost",
  port: "8098"
});

fs = require('fs');

crypto = require('crypto');

output = require('../output');

dataWriter = require('../dataWriter');

executable = "pdf2htmlEX";

executalbeParams = "--embed-css=0 --embed-font=0 --embed-image=0 --embed-javascript=0";

exports.go = function(localCopy, docLogger, req, res) {
  var fileContent, hash, hasher, name;
  name = localCopy.replace("../local-copies/pdf/", "").replace(".pdf", "");
  req.session.name = name;
  hasher = crypto.createHash('md5');
  fileContent = fs.readFileSync(localCopy);
  util.timelog(name, "hashing input file");
  hasher.update(fileContent);
  hash = hasher.digest('hex');
  util.timelog(name, "hashing input file");
  logging.cond("input file hash is: " + hash, "hash");
  return riak.get('html', hash, function(error, formerName) {
    var execCommand, input, outFolder, path;
    if (error != null) {
      util.timelog(name, "from upload to serving");
      docMeta.storePdfMetaData(name, localCopy, docLogger);
      storage.store("pdf", name, fileContent, docLogger);
      util.timelog(name, "Conversion to html");
      logging.cond("starting the conversion from pdf to html", 'progress');
      execCommand = executable + " ";
      outFolder = "../local-copies/" + "html-converted/";
      execCommand += '"' + localCopy + '"' + " " + executalbeParams + " " + "--dest-dir=" + '"' + outFolder + "/" + name + '"';
      dataWriter.write(name, 'pdfToHtml', execCommand);
      return exec(execCommand, function(error, stdout, stderr) {
        var input, outFolderResult, path, resultFile, _i, _len, _ref;
        dataWriter.write(name, 'pdfToHtml', executable + "'s stdout: " + stdout);
        dataWriter.write(name, 'pdfToHtml', executable + "'s stderr: " + stderr);
        if (error !== null) {
          return dataWriter.write(name, 'pdfToHtml', executable + "'sexec error: " + error);
        } else {
          outFolderResult = outFolder + name + '/';
          _ref = fs.readdirSync(outFolderResult);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            resultFile = _ref[_i];
            if (fs.statSync(outFolderResult + resultFile).isFile()) {
              if (util.extensionFilter(resultFile)) {
                util.mkdir(dataWriter.docDataDir, name);
                util.mkdir(dataWriter.docDataDir + '/' + name, 'html-converted');
                fs.createReadStream(outFolderResult + resultFile).pipe(fs.createWriteStream(dataWriter.docDataDir + '/' + name + '/' + 'html-converted' + '/' + resultFile));
              }
            }
          }
          util.timelog(name, "Conversion to html");
          riak.save('html', hash, name, function(error) {
            if (error != null) {
              return console.log('pdfToHtml', "failed storing file hash for " + name + " to clustered storage");
            } else {

            }
          });
          path = outFolder;
          input = {
            'html': path + name + '/' + name + ".html",
            'css': path + name + '/'
          };
          return require('./extract').go(req, name, input, res, docLogger);
        }
      });
    } else {
      logging.cond('input file has already passed pdf2htmlEX conversion - skipping conversion', 'fileMgmt');
      path = '../local-copies/' + 'html-converted/';
      input = {
        'html': path + formerName + '/' + formerName + ".html",
        'css': path + formerName + '/'
      };
      return require('./extract').go(req, name, input, res, docLogger);
    }
  });
};

redirectToShowHtml = function(redirectString) {
  docLogger.info("Passing html result to next level handler, by redirecting to: " + redirectString);
  res.writeHead(301, {
    Location: redirectString
  });
  return res.end();
};

redirectToExtract = function(redirectString) {
  docLogger.info("Passing html result to next level handler, by redirecting to: " + redirectString);
  res.writeHead(301, {
    Location: redirectString
  });
  return res.end();
};
