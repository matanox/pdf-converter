logging = require './logging' 

#
# For interpretation see http://stackoverflow.com/questions/12023359/what-do-the-return-values-of-node-js-process-memoryusage-stand-for and others
# This will ultimately UDP to our own monitoring server.
#

former = null
later  = null
percentThreshold = 10
interval = 1000 # milliseconds

getMem = () ->
  mem = process.memoryUsage()  
  mem.heapPercent = mem.heapUsed / mem.heapTotal * 100 # enrich with calculated value
  mem

logUsage = (mem, verb) -> 
  logging.logPerf('v8 heap usage ' + verb + ' ' + parseInt(mem.heapUsed/1024/1024) + 'MB' + ' ' + 
  	              '(now comprising ' + parseInt(mem.heapPercent) + '% of heap)')

logHeapSize = (mem, verb) -> 
  logging.logPerf('v8 heap ' + verb + ' ' + parseInt(mem.heapTotal/1024/1024) + 'MB')

logUsageIfChanged = () ->

  later = getMem()

  if (Math.abs(later.heapTotal - former.heapTotal) / former.heapTotal) > (percentThreshold/100)
  	if later.heapTotal > former.heapTotal
  	  logHeapSize(later, 'grew to')
  	else 
  	  logHeapSize(later, 'shrank to')

  if (Math.abs(later.heapPercent - former.heapPercent) / former.heapPercent) > (percentThreshold/100)
  	if later.heapUsed > former.heapUsed
  	  logUsage(later, 'increased to')
  	else 
  	  logUsage(later, 'decreased to')

  #logging.logPerf('on interval')
  former = later

exports.start = () ->

  former = getMem()
  logHeapSize(former, 'is')
  logUsage(former, 'is')

  process.nextTick(() -> setInterval(logUsageIfChanged, interval)) # next-ticking it so initial logging would finish first
