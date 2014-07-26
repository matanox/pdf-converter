#
# non-blocking file writer
#

fs = require 'fs'
opens = 0
closes = 0
requestCloses = 0

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
  console.log """opened file #{fileName}"""
 
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
        console.log """closes #{closes} : request closes #{requestCloses} : opens #{opens}"""

  toWrite = this.dataQueue.slice().join('\n')    # create copy of the queue, and flatten it
  buff = new Buffer(toWrite)
  this.dataQueue = []                          # now clear the queue
  fs.write(this.fd, buff, 0, buff.length, null, this._writeDone)


#
# Write or queue
#
writer.prototype.write = (data) ->

  if this.pendingClose 
    console.error "attempting to write to file #{this.fileName} that is already pending closure"
    return

  if not this.opened
    this.dataQueue.push data
  else
    if not this.writing 
      this.writing = true
      this.dataQueue.push data
      this._appendQueue()
    else
      this.dataQueue.push data

writer.prototype.close = () ->

  requestCloses += 1

  if not this.opened
    console.error "attempting to close file #{this.fileName} that is not open"
    return

  switch this.writing
  
    when false

      closes +=1
      fs.closeSync(this.fd)
      console.log """closes #{closes} : request closes #{requestCloses} : opens #{opens}"""

    when true 
      this.pendingClose = true


