exec   = require("child_process").exec
util    = require '../util/util'
logging = require '../util/logging' 
dataWriter = require '../data/dataWriter'

module.exports = (cmd, callback) ->
    exec cmd, (error, stdout, stderr) ->
      if stderr
        console.log """stderr: #{stderr}"""
      if error isnt null 
        console.error """execution of shell command #{cmd} failed with error: \n #{error}"""
        callback(error, stdout, stderr)

      callback(null, stdout, stderr)