r = require './rdbms'

purge = () -> 
  r.reinit()

wait = 2
console.log ""
console.log """ATTENTION!!! if not interupted the app rdbms will be purged in #{wait} seconds"""
console.log ""
setTimeout(purge, wait * 1000)

