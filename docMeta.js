// Generated by CoffeeScript 1.6.3
var util;

util = require("./util");

exports.storePdfMetaData = function(localCopy) {
  var execCommand;
  console.log("Getting pdf file metadata using pdfinfo");
  util.timelog("Getting pdf file metadata using pdfinfo");
  execCommand = 'pdfinfo -meta' + ' ';
  execCommand += localCopy;
  console.log(execCommand);
  return exec(execCommand, function(error, stdout, stderr) {
    var meta;
    console.log(executable + "'s stdout: " + stdout);
    console.log(executable + "'s stderr: " + stderr);
    if (error !== null) {
      return console.log(executable + "'sexec error: " + error);
    } else {
      util.timelog("Getting pdf file metadata using pdfinfo");
      meta = {
        raw: stdout,
        stderr: stderr
      };
      return console.dir(meta);
    }
  });
};