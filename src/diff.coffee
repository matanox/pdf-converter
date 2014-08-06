nconf = require('nconf')
nconf.argv().env().file({file: 'loggingConf.json'})
compare = require './compare/get'
compare.diff('irrelevant', 'irrelevant')