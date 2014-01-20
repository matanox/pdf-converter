http = require 'http'
fs = require 'fs'
nconf = require 'nconf'
util = require '../../util'
logging = require '../../logging'
#timer = require("../../timer")

nconf.argv().env()
nconf.defaults host: "localhost"
host = nconf.get "host"

logging.logGreen 'Running against host: ' + nconf.get('host') + '...'
logging.logGreen ''

http.globalAgent.maxSockets = 1000 # omitting this, and this client-side pauses after the 5 first client-side
                                   # node.js requests that saturate the client agent pool (per current default), 
                                   # to a rhythm affected by the keepalive dynamics with the server-side
                                   # and practically take whole minutes to execute..... 
                                   # This definition removes this concurrency limitation from the client-side.

# createCallBack = (callback, paramToFix) ->
# httpCallBack()

# invoke for all files in a directory
directory = '../local-copies/pdf/'

requests = 0
responses = 0

# Initializing for an aggregation of overall response await time
aggregateWait = 0

util.timelog 'Overall duration'

for filename in fs.readdirSync(directory)
  if fs.statSync(directory + filename).isFile() 
    if filename != '.gitignore'
      requests += 1
      httpCallBack = ((filename) -> 
        (res) ->
          responses +=1
          if res.statusCode is 200
            logging.logGreen 'Server response for ' + filename + ' is:   ' + res.statusCode
          else 
            logging.logYellow 'Server response for ' + filename + ' is:   ' + res.statusCode

          console.log responses + ' responses out of ' + requests + ' requests received thus far'
          requestElapsedTime = util.timelog 'Server response for ' + filename

          # add up time waited for this request, to the overal wait impact metric
          aggregateWait += (requestElapsedTime / 1000)

          if responses is requests
            util.timelog 'Overall '
            logging.logPerf ''
            logging.logPerf '-----------------------------'
            logging.logPerf 'Aggregate response await time'
            logging.logPerf 'time: '      + aggregateWait
            logging.logPerf 'normalized:' + (aggregateWait / responses)
            logging.logPerf ''
            process.exit(0) 
            return) (filename)

      console.log "Requesting " + directory + filename
      util.timelog 'Server response for ' + filename
      
      # Invoke api request
      http.get 'http://' + host + '/handleInputFile?' + 'localLocation=' + filename, httpCallBack 
    else
      console.log 'Skipping .gitignore' 
  else
    console.log 'Skipping subdirectory ' + filename
