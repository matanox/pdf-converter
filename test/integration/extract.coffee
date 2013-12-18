http = require("http")
fs = require("fs")
nconf = require("nconf")
timer = require("../../timer")

nconf.argv().env()
nconf.defaults host: "localhost"
host = nconf.get "host"
console.log "host to test: " + nconf.get("host")

http.globalAgent.maxSockets = 1000

# createCallBack = (callback, paramToFix) ->
# httpCallBack()

# invoke for all files in a directory
directory = '../local-copies/html-converted/'

for filename in fs.readdirSync(directory)
  if filename != '.gitignore'

    httpCallBack = ((filename) -> 
      (res) ->
        timer.end 'server response for ' + filename
        console.log 'server response for ' + filename + ' is:   ' + res.statusCode)(filename)

    console.log "requesting " + directory + filename
    timer.start 'server response for ' + filename
    http.get 'http://' + host + '/extract?name=' + filename, httpCallBack

  else
    console.log 'skipping .gitignore' 
