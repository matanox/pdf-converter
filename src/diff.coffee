nconf = require('nconf')
nconf.argv().env().file({file: 'loggingConf.json'})
compare = require './compare/get'
compare.diff('gender differences 2013', 'sentences')