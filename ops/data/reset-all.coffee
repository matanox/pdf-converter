#
# Quick and dirty reset all data forms
#

Promise = require 'bluebird'
rdbms         = require '../../src/storage/rdbms/rdbms-reset'
dataFiles     = require '../../src/data/reset.coffee'
simpleStorage = require '../../src/storage/simple/reset'
