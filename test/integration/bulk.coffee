http = require 'http'
fs = require 'fs'
nconf = require 'nconf'
util = require '../../src/util/util'
logging = require '../../src/util/logging'

nconf.argv().env()
nconf.defaults host: "localhost", serial: true

host = nconf.get 'host'
logging.logGreen 'Using hostname ' + nconf.get('host')
port = process.env.PORT or 3080
logging.logGreen 'Using port ' + port

serial = nconf.get "serial"
switch serial
  when false
    logging.logGreen 'Running in concurrent mode'
  when true
    logging.logGreen 'Running in serial mode'
  else
    logging.logYellow "Invalid value supplied for the --serial argument, value can only be true or false"
    process.exit(0)

logging.logGreen """Running against host #{host}, port #{port} ..."""

logging.logGreen ''

http.globalAgent.maxSockets = 1000 # omitting this, and this client-side pauses after the 5 first client-side
                                   # node.js requests that saturate the client agent pool (per current default), 
                                   # to a rhythm affected by the keepalive dynamics with the server-side
                                   # and practically take whole minutes to execute..... 
                                   # This definition removes this concurrency limitation from the client-side.


# scan for files in the input directory
directory = '../local-copies/pdf/'

requests = 0
responses = 0

# Initializing for an aggregation of overall response await time
aggregateWait = 0

makeRequest = (filename) ->

  requests += 1
  httpCallBack = ((filename) -> 
    (res) ->

      responses +=1

      # get the server response data
      responseBody = ''

      res.on('data', (chunk) -> responseBody += chunk)

      res.on('end', () -> 
        if res.statusCode is 200
          logging.logGreen 'Server response for ' + filename + ' is:   ' + res.statusCode
        else 
          logging.logYellow 'Server response for ' + filename + ' is:   ' + res.statusCode + ', ' + responseBody

        if serial
          # Invoke next request unless all requests already made
          toRequest.shift()
          if toRequest.length > 0 
            makeRequest(toRequest[0])

        console.log responses + ' responses out of ' + requests + ' requests received thus far'
        requestElapsedTime = util.timelog null, 'Server response for ' + filename

        # add up time waited for this request, to the overal wait impact metric
        aggregateWait += (requestElapsedTime / 1000)

        if responses is requests
          logging.logPerf ''
          util.timelog null, 'Overall'
          logging.logPerf ''
          logging.logPerf '-----------------------------'
          logging.logPerf 'Aggregate response await time'
          logging.logPerf 'time:       ' + aggregateWait + ' secs'
          logging.logPerf 'normalized: ' + (aggregateWait / responses)
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

toRequest = []
for filename in fs.readdirSync(directory)
  if fs.statSync(directory + filename).isFile() 
    if filename != '.gitignore'
      toRequest.push(filename)
    else
      console.log 'Skipping .gitignore' 
  else
    console.log 'Skipping subdirectory ' + filename

if toRequest.length > 0
  if serial
    makeRequest(toRequest[0])
  else
    for filename in toRequest
      makeRequest(filename)
else
  logging.logYellow 'No files to process in directory. Existing.'
    
    