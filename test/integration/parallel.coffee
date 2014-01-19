http = require("http")
fs = require("fs")
nconf = require("nconf")
timer = require("../../timer")

nconf.argv().env()
nconf.defaults host: "localhost"
host = nconf.get "host"
console.log "host to test: " + nconf.get("host")

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
for filename in fs.readdirSync(directory)
  if fs.statSync(directory + filename).isFile() 
    if filename != '.gitignore'
      requests += 1
      httpCallBack = ((filename) -> 
        (res) ->
          responses +=1
          timer.end 'server response for ' + filename
          console.log 'server response for ' + filename + ' is:   ' + res.statusCode
          console.log responses + ' responses out of ' + requests + ' requests received thus far') (filename)

      console.log "requesting " + directory + filename
      timer.start 'server response for ' + filename
      
      # Invoke api request
      http.get 'http://' + host + '/handleInputFile?' + 'localLocation=' + filename, httpCallBack 
    else
      console.log 'skipping .gitignore' 
  else
    console.log 'skipping subdirectory ' + filename
