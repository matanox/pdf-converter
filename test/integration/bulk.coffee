http    = require 'http'
fs      = require 'fs'
nconf   = require 'nconf'
util    = require '../../src/util/util'
logging = require '../../src/util/logging'

nconf.argv().env()
nconf.defaults 
  host        : "localhost"
  directory   : '../local-copies/pdf/'
  flood       : false
  parallelism : 2
  maxFiles    : 10

#
# log the configuration
#
host = nconf.get 'host'
port = process.env.PORT or 3080
logging.logGreen 'Using hostname ' + nconf.get('host')
logging.logGreen 'Using port ' + port

directory = nconf.get 'directory' # input directory 
logging.logGreen 'Invoking over input files from ' + util.terminalClickableFileLink(directory)

flood = nconf.get 'flood'
switch flood
  when true
    logging.logPerf 'Running in flood mode'
  when false
    logging.logPerf 'Running in controlled load mode' 
  else
    logging.logYellow 'Invalid value for the flood argument'
    process.exit(0)
    
parallelism = nconf.get 'parallelism'
logging.logPerf """Degree of parallelism: #{parallelism}"""

maxFiles = nconf.get 'maxFiles'

logging.logGreen ''


#logging.logGreen """Running against host #{host}, port #{port} ..."""


http.globalAgent.maxSockets = 1000 # omitting this, and this client-side pauses after the 5 first client-side
                                   # node.js requests that saturate the client agent pool (per current default), 
                                   # to a rhythm affected by the keepalive dynamics with the server-side
                                   # and practically take whole minutes to execute..... 
                                   # This definition removes this concurrency limitation from the client-side.



requests = 0
responses = 0
aggregateRequestsWait = 0 # summed requests wait time 

makeRequest = (filename) ->

  requests += 1
  httpCallBack = ((filename) -> 
    (res) ->

      responses += 1

      # get the server response data
      responseBody = ''

      res.on('data', (chunk) -> responseBody += chunk)

      res.on('end', () -> 
        if res.statusCode is 200
          logging.logGreen 'Server response for ' + filename + ' is:   ' + res.statusCode
        else 
          logging.logYellow 'Server response for ' + filename + ' is:   ' + res.statusCode + ', ' + responseBody

        unless flood
          # Invoke next request unless all requests already made
          if toRequest.length > 0
            makeRequest(toRequest.shift())

        console.log responses + ' responses out of ' + requests + ' requests received thus far'
        requestElapsedTime = util.timelog null, 'Server response for ' + filename

        # add up time waited for this request, to the overal wait impact metric
        aggregateRequestsWait += (requestElapsedTime)

        if responses is requests
          overall = util.timelog null, 'Overall'
          logging.logPerf ''
          logging.logPerf ' Timing:'
          logging.logPerf ''
          logging.logPerf ' elapsed   ' + overall / 1000 + ' secs'
          logging.logPerf ' averaged  ' + overall / 1000 / responses + ' (sec/request)'
          logging.logPerf ' wait time ' + aggregateRequestsWait / 1000 + ' secs (typically more than elapsed time'
          logging.logPerf ' averaged  ' + aggregateRequestsWait / 1000 / responses + ' (sec/request)'
          logging.logPerf ''
          logging.logPerf """ Parallelism degree employed was #{parallelism}"""
          logging.logPerf ''
          process.exit(0) 
          return)) (filename) # Callback application

  console.log "Requesting " + directory + filename
  util.timelog null, 'Server response for ' + filename

  # Invoke api request
  http.get 
    host: host
    port: port
    path: '/handleInputFile?' + 'localLocation=' + encodeURIComponent(filename)
    method: 'GET',
    httpCallBack 
  .on('error', (e) ->
    console.log("Got error: " + e.message))

util.timelog null, 'Overall'

#
# build queue of requests - per elligible input files in the supplied input directory
#
toRequest = []
for filename in fs.readdirSync(directory)
  if fs.statSync(directory + filename).isFile() 
    if filename isnt '.gitignore'
      #console.log toRequest.length
      #console.log maxFiles
      if toRequest.length < maxFiles
        toRequest.push(filename)
    else
      console.log 'Skipping .gitignore' 
  else
    console.log 'Skipping subdirectory ' + filename

#
# start the requests
#
if toRequest.length > 0 
  unless flood
    if parallelism > toRequest.length
      logging.logYellow 'Note: specified degree of parallelism is greater than number of files to process'    
    for i in [1..parallelism]
      if toRequest.length > 0
        makeRequest(toRequest.shift()) # remove bottom of queue and issue request for it
  else
    for filename in toRequest
      makeRequest(filename)
else
  logging.logYellow 'No files to process in directory. Existing.'
    
    