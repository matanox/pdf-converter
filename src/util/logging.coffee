#
# Some logging utilities, admiteddly not uniformly used across the project
# Winston also breaks under load (messages vanish, so we'll if we keep it)
#

nconf = require('nconf')

# conditional logging
exports.cond = (message, tag) ->
  enabledTags = nconf.get 'tagsEnabled'
  if tag in enabledTags
    console.log message

winston = require 'winston'

log = (level, msgOrObj) -> winston.log(level, msgOrObj)

exports.log   = (msgOrObj) -> log('info',  msgOrObj)
exports.warn  = (msgOrObj) -> log('warn',  msgOrObj)
exports.error = (msgOrObj) -> log('error', msgOrObj)

exports.init = () ->
  #winston.remove(winston.transports.Console) # turn off winston's default console logging

# This coloring is terminal color based. 
# It doesn't work for the browser console. For browser console solutions (which are all based on css) 
# see http://stackoverflow.com/questions/7505623/colors-in-javascript-console/13017382.
#
# It's easy to create a function that provides the same API for both.... similar to 
# stuff in https://github.com/visionmedia/node-term-css.
#

tty = {
  green:    '\x1b[32m'
  red  :    '\x1b[31m'  
  yellow:   '\x1b[33m'  
  blue:     '\x1b[36m'  
  magenta:  '\x1b[35m'
  bold:     '\x1b[1m'
  italics:  '\x1b[3m'
  end:      '\x1b[0m'
}

exports.bold = (text) ->
  tty.bold + text + tty.end

exports.italics = (text) ->
  tty.italics + text + tty.end

exports.logBold  = (text) -> 
  console.log(tty.bold + text + tty.end)

exports.logGreen  = (text, bold) -> 
  if bold?
    console.log(tty.green + tty.bold + text + tty.end)
  else
    console.log(tty.green + text + tty.end)
exports.logYellow = (text) -> console.log(tty.yellow + text + tty.end)
exports.logRed    = (text) -> console.log(tty.red + text + tty.end)
exports.logBlue   = (text) -> console.log(tty.blue + text + tty.end)
exports.logPerf   = (text) -> console.log(tty.magenta + text + tty.end)

# Color codes at http://telepathy.freedesktop.org/doc/telepathy-glib/telepathy-glib-debug-ansi.html
# See more terminal codes at if in need of more styles:
# https://github.com/Marak/colors.js/blob/master/colors.js 
# https://github.com/Marak/colors.js                       



#
# Logging facilities that were less suitable than winston at time of writing:
#

testLogio = () ->
  require 'winston-logio' 
  winston.add(winston.transports.Logio, {
      port: 28777,
      node_name: 'nodejs',
      host: '127.0.0.1'
    });
 
  winston.log('info', 'Hello to logio')

testGraylog2 = () ->
  winston.add(require('winston-graylog2').Graylog2, {})
  winston.log('info', 'Hello to graylog2')

#
# for logstash, use the library recommended on by the logstash website:
# https://github.com/nlf/bucker. Not Winston.
#

testWinstonLogstash = () ->
  #
  # This requires special configuration in logstash and is buggy for objects
  #
  log = (level, msgOrObj) ->
    if typeof msgOrObj isnt 'object'
      winston.log(level, msgOrObj)
    else
      winston.log(level, msgOrObj)

  exports.log  = (msgOrObj) -> log('info', msgOrObj)
  exports.warn = (msgOrObj) -> log('warn', msgOrObj)

  exports.init = () ->
    require('winston-logstash')
    winston.remove(winston.transports.Console) # turn off winston's default console logging
    winston.add(winston.transports.Logstash, {port: 28777, node_name: 'nodejs', host: '127.0.0.1'})
  
  #sub = {sub: 'sub'}
  #logSample = {a: '3', b: 'bbbb', sub}
  #winston.log('warn', 'New Hello to logstash')
  #winston.log('warn', logSample)
