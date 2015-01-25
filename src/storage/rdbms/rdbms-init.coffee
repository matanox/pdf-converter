nconf = require('nconf')
nconf.add('other-configuration', {type: 'file', file: '../config/config.json'})

r = require './rdbms'

r.init() 

console.log ""
console.log """initializing database parts for pdf extraction"""
console.log ""

