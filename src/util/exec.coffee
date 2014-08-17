exec   = require("child_process").execFile
util    = require '../util/util'
logging = require '../util/logging' 
dataWriter = require '../data/dataWriter'

module.exports = (executable, executalbeParams, callback) ->
    exec executable, executalbeParams, (error, stdout, stderr) ->
      if stderr
        console.log """stderr: #{stderr}"""
      if error isnt null 
        console.error """execution of binary/shell file #{executable} failed with error: \n #{error}"""
        callback(false)

      callback(true)