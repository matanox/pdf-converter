#
# non-blocking file writer
#
# TODO: creating a new buffer (which probably results in malloc) every time is entirely wasteful.
#       should reuse some pre-allocated buffer, or switch to the appendFile api that accepts plain strings 
#       and avoids the need to manage file closes.
#
#
#

fs = require 'fs'
logging  = require '../util/logging' 

#
# debug logging counters
#
opens = 0
closes = 0
requestCloses = 0

#
# The writer object prototype
#
writer = module.exports = (fileName) -> 

  self = this

  this.fileName = fileName

  this.writing      = false
  this.opened       = false
  this.pendingClose = false
  this.dataQueue    = []

  ###
  fs.open(fileName, 'wx', (error, fd) ->
           unless error
             self.fd = fd
             self.opened = true 
             console.log """opened file #{fileName}"""
           else
             console.error """failed opening data writing file #{fileName}: #{error}"""
         )
  ###

  fd = fs.openSync(fileName, 'wx')
  opens += 1

  this.fd = fd
  this.opened = true 
  logging.cond """opened data file #{fileName}""", 'dataWriter'
 
writer.prototype._appendQueue = () ->

  self = this

  #
  # callback invoked when previous write finished
  # if there's pending data to write now, it handles that
  #
  writer.prototype._writeDone = () ->

    if self.dataQueue.length > 0
      self._appendQueue()
    else
      self.writing = false
      if self.pendingClose 
        closes +=1
        fs.closeSync(self.fd)
        logging.cond """closes #{closes} : request closes #{requestCloses} : opens #{opens}""", 'dataWriter'

  toWrite = this.dataQueue.slice().join('')    # create copy of the queue, and flatten it
  buff = new Buffer(toWrite)
  this.dataQueue = []                          # now clear the queue
  fs.write(this.fd, buff, 0, buff.length, null, this._writeDone)

#
# appends new line to a data row.
# can later be used also for any formatting or normalization stage.
#
append = (queue, data) ->
  queue.push data + '\n'

#
# Write or queue
#
writer.prototype.write = (data) ->

  if this.pendingClose 
    console.error "attempting to write to file #{this.fileName} that is already pending closure"
    return

  if not this.opened
    append this.dataQueue, data
  else
    if not this.writing 
      this.writing = true
      append this.dataQueue, data
      this._appendQueue()
    else
      append this.dataQueue, data

writer.prototype.close = () ->

  requestCloses += 1

  if not this.opened
    console.error "attempting to close file #{this.fileName} that is not open"
    return

  switch this.writing
  
    when false

      closes +=1
      fs.closeSync(this.fd)
      logging.cond """data file closes #{closes} : request closes #{requestCloses} : opens #{opens}""", 'dataWriter'

    when true 
      this.pendingClose = true
