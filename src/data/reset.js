// Generated by CoffeeScript 1.6.3
var Promise, docsDataDir, exec, purge, wait, waitAndGo;

exec = require('../util/execOsCommand');

Promise = require('bluebird');

wait = 2;

purge = function() {
  return exec("rm " + docsDataDir + "/* -r", function(error) {
    if (error) {
      console.error('purging the local data-files repository failed');
      throw error;
    }
  });
};

waitAndGo = function(docsDataDir) {
  console.log("");
  console.log("ATTENTION!!! if not interupted, the local data-files repository (" + docsDataDir + ") will be purged in " + wait + " seconds");
  console.log("");
  return setTimeout(purge, wait * 1000);
};

return;

docsDataDir = require('../data/dataWriter').docsDataDir;

if (docsDataDir.length < 3) {
  console.error('Internal Error: local data-files directory must be over 2 characters in length. Purge aborted.');
  return;
}

exec("ls " + docsDataDir, function(error, stdout, stderr) {
  if (error) {
    throw error;
  }
  if (stdout.length === 0) {
    console.log('local data-files repository does not yet exist, nothing to do');
    return;
  }
  return waitAndGo(docsDataDir);
});
