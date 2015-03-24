nconf = require('nconf')
dataFilesRoot = exports.dataFilesRoot = nconf.get("dataFilesRoot") or "../data/"
exports.rooted = (path) -> dataFilesRoot + path
