#
# mildly intelligent self memory monitoring
#

logging = require './logging' 
exec    = require("child_process").exec  # for issuing lsof

#
# For interpretation see http://stackoverflow.com/questions/12023359/what-do-the-return-values-of-node-js-process-memoryusage-stand-for and others
# This will ultimately UDP to our own monitoring server.
#

formerMem = null
laterMem  = null

formerFD = null
laterFD  = null

percentThreshold = 10

memCheckInterval = 1000           # milliseconds
fDescriptorsCheckInterval = 10000 # milliseconds

getMem = () ->
  mem = process.memoryUsage()  
  mem.heapPercent = mem.heapUsed / mem.heapTotal * 100 # enrich with calculated value
  mem

logMemUsage = (mem, verb) -> 
  logging.logPerf('v8 heap usage ' + verb + ' ' + parseInt(mem.heapUsed/1024/1024) + 'MB' + ' ' + 
  	              '(now comprising ' + parseInt(mem.heapPercent) + '% of heap)')

logHeapSize = (mem, verb) -> 
  logging.logPerf('v8 heap ' + verb + ' ' + parseInt(mem.heapTotal/1024/1024) + 'MB')

logMemUsageIfChanged = () ->

  laterMem = getMem()

  if (Math.abs(laterMem.heapTotal - formerMem.heapTotal) / formerMem.heapTotal) > (percentThreshold/100)
  	if laterMem.heapTotal > formerMem.heapTotal
  	  logHeapSize(laterMem, 'grew to')
  	else 
  	  logHeapSize(laterMem, 'shrank to')

  if (Math.abs(laterMem.heapPercent - formerMem.heapPercent) / formerMem.heapPercent) > (percentThreshold/100)
  	if laterMem.heapUsed > formerMem.heapUsed
  	  logMemUsage(laterMem, 'increased to')
  	else 
  	  logMemUsage(laterMem, 'decreased to')

  #logging.logPerf('on memCheckInterval')
  formerMem = laterMem

memTracking = () ->
  formerMem = getMem()
  logHeapSize(formerMem, 'is')
  logMemUsage(formerMem, 'is')

  process.nextTick(() -> setInterval(logMemUsageIfChanged, memCheckInterval)) # next-ticking it so initial logging would finish first

getFileDescriptorsCount = (callback) ->
  execCommand = """lsof -p #{process.pid} | wc -l""" # get number of file descriptors assigned by this node.js process
  exec execCommand, (error, stdout, stderr) ->
    if error isnt null
      console.warn 'could not use lsof to determine number of file descriptors'
      callback(null)
    else
      callback(parseInt(stdout))


logFileDescriptorsCountIfChanged = () ->
  getFileDescriptorsCount((count) -> 
    laterFD = count
    if (Math.abs(laterFD - formerFD) / formerFD) > (percentThreshold/100)
      logging.logPerf("""this node.js process is currently using #{laterFD} file descriptors""")

    formerFD = laterFD
  )

fileDescriptorsTracking = () ->
  getFileDescriptorsCount((count) -> laterFD = count)
  process.nextTick(() -> setInterval(logFileDescriptorsCountIfChanged, fDescriptorsCheckInterval)) # next-ticking it so initial logging would finish first

exports.start = () ->
  memTracking()
  fileDescriptorsTracking()

