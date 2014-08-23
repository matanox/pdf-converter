exec   = require("child_process").execFile
util    = require '../util/util'
logging = require '../util/logging' 
dataWriter = require '../data/dataWriter'

#
# execute an executable with arguments, calling back a callback 
# following the promisification required standard behavior (https://github.com/petkaantonov/bluebird/blob/master/API.md#promisepromisifyfunction-nodefunction--dynamic-receiver---function)
#
module.exports = (executable, executalbeParams, callback) ->
    exec executable, executalbeParams, (error, stdout, stderr) ->
      if stderr
        console.log """stderr: #{stderr}"""
      if error isnt null 
        error = """execution of binary/shell file #{executable} failed with error: \n #{error}"""
        console.error 
        callback(error, null) # standard adhering error indication

      callback(null, true) # standard adhering success indication
      return