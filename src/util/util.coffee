#
# Various utility functions (not all should necessarily stay here)
#

logging = require './logging' 
winston = require 'winston'
dataWriter = require '../data/dataWriter'
# crepl = require 'coffee-script/lib/coffee-script/repl'

exports.anySpaceChar = anySpaceChar = RegExp(/\s/)

# Regexes for any html character reference. E.g. &amp &lt, etc.
exports.htmlCharacterEntity = RegExp(/&.*\b;$/) # delimited with any non-word character (html 4)

exports.endsWith = endsWith = (string, match) ->
  string.lastIndexOf(match) is string.length - match.length

#
# return suffix trimmed version of input string, if it ends with the specified suffix
# e.g. remove trailing \n of a string.
#
exports.trimLast = trimLast = (string, match) ->
  if endsWith(string, match)
    return string.substr(0, string.length - match.length - 1)
  else
    return string

exports.startsWith = startsWith = (string, match) ->
  string.indexOf(match) is 0

contains = (string, match) ->
  string.indexOf(match) isnt -1

#
# Strip a string from a given header and trailer, if they indeed are.
#
exports.strip = (string, prefix, suffix) ->
  if !startsWith(string, prefix)
    throw("Cannot strip string of the supplied prefix")
  if !endsWith(string, suffix)
    throw("Cannot strip string of the supplied suffix")

  string.slice(string.indexOf(prefix)+prefix.length, string.lastIndexOf(suffix))      

# Utilty function for checking if a string matches any of a given set of strings.
# Regex building could be an alternative implementation...
exports.isAnyOf = isAnyOf = (string, matches) ->
  matches.some((elem) -> elem.localeCompare(string, 'en-US') == 0)

# return unique values of an input array
exports.unique = (array, preserveFloat) ->
  temp = {}
  result = []
  for item in array
    temp[item] = true
  for key, value of temp
    if preserveFloat
      result.push(parseFloat(key))
    else
      result.push(key)
  result

# For sizing map objects. 
# Returns object's number of properties
exports.objectPropertiesCount = (object) -> Object.keys(object).length

exports.endsWithAnyOf = (string, matches) ->
  trailingChar = string.charAt(string.length - 1)
  return false unless isAnyOf(trailingChar, matches)
  return trailingChar

exports.startsWithAnyOf = (string, matches) ->
  char = string.charAt(0)
  return false unless isAnyOf(char, matches)
  return char

exports.isAnySpaceChar = (char) -> anySpaceChar.test(char) 

exports.isSpaceCharsOnly = (string) -> 
  for i in [0..string.length()-1]
    unless isAnySpaceChar(string.charAt[i]) then return false
  return true  

exports.lastChar = (string) -> string.charAt(string.length - 1)

exports.last = (array) -> array[array.length - 1]

exports.first = (array) -> array[0]

exports.parseElementTextOld = (xmlNode) ->
  content = xmlNode.substr(0, xmlNode.length - "</div>".length) # remove closing div tag
  content = content.slice(content.indexOf(">") + 1)             # remove opening div tag
  content

#exports.arrayToMap = (array) ->
  #map[obj[key]] = element for element in array 

exports.logObject = (obj) -> logging.log(JSON.stringify obj, null, 2) 

#
# Nice elapsed time logging utility function.
# Usage: Call it once to start a timer, and once to end it. The call is the same for
#        both starting and ending a timer - just supply the same timer description string to both.
#        The second call will log the time elapsed between the two. 
#
exports.timelog = timelog = (name, timer, logger) ->
  #timer = timer + ' took'                                    # the timer string is also the message 
                                                              # it will log to the console when it ends.
                                                             
  unless timelog.timersLookup? then timelog.timersLookup = {} # init timers array only once
  
  if timelog.timersLookup[timer]?                             # is this timer already started?
    #console.timeEnd(timer)
    end = new Date()
    elapsed = (end.getTime() - timelog.timersLookup[timer])
    timerText = timer + ' took: ' + elapsed + ' ms'
    if logger?
      logger.info(timerText)
    else
      if name?
        dataWriter.write(name, 'timers', timerText)
        logging.cond(timerText, 'timers')
      else
        console.log timerText

    delete timelog.timersLookup[timer]
    return elapsed

  else                                                        # or is it starting now?
    start = new Date()
    timelog.timersLookup[timer] = start.getTime()
    return null
    #console.time(timer)

  # We should later also send this data to an analytics engine or depo. 
  # or Apache Kafka or equivalents could be good for grabbing from the logs and/or queueing/transport
  
exports.objectViolation = (errorMessage) ->
  error = new Error(errorMessage)
  logging.log(error.stack)
  throw error   

#
# Deep object copy
#
clone = (obj) ->

  # If it's a primitive type, return as is
  if not obj? or typeof obj isnt 'object' 
    return obj

  newInstance = {}

  # Iterate and recurse for a full clone
  for key of obj
    newInstance[key] = clone obj[key] 

  newInstance

exports.clone = clone

exports.pushIfTrue = (array, functionResult) ->
    if functionResult
      array.push(functionResult)
      return true
    return false

exports.simpleLogSequence = (tokens, sequence, heading) -> 
  console.log heading+':' if heading?
  output = ''
  for t in [sequence.startToken..sequence.endToken]
    token = tokens[t]
    if token.text?
      output += token.text 
    else 
      output += ' '

  console.log output

exports.markTokens = (tokens, sequence, mark) -> 
  for t in [sequence.startToken..sequence.endToken]
    token = tokens[t]
    token.meta = mark 

exports.initDocLogger = (name) ->
  #
  # Initialize logger for this document
  #
  docLogger = new winston.Logger
  now = new Date()
  docLoggerNameBase = 'logs/' + name + '-' + now.toISOString() + '.log' 
  
  ###
  docLogger.add(winston.transports.File, {
    filename: docLoggerNameBase + '.json',
    json: true
    timestamp: true})
  ###
    
  docLogger = new winston.Logger
    transports: [
      new winston.transports.File
        name: 'file#json'
        filename: docLoggerNameBase + '.json',
        json: true
        timestamp: true
      new winston.transports.File
        name: 'file#text'
        filename: docLoggerNameBase,
        json: false
        timestamp: true
    ], exitOnError: false

  docLogger

exports.closeDocLogger = (docLogger) ->
  docLogger.close()

fs = require 'fs'
#
# create a directory in an existing subdirectory, if it doesn't already exist there
#
exports.mkdir = (path, subDir) ->
  try 
    fs.mkdirSync(path + '/' + subDir)
  catch err
    if err.code isnt 'EEXIST' # is the error code indicating the directory already exists? if so all is fine
      throw err               # on different error, re-throw the error

exports.extensionFilter = (filename) ->
  extensions = ['html', 'htm', 'css', 'js']
  for extension in extensions
    if filename.indexOf('.' + extension) > -1
      return true                
  return false

#
# replace all occurences inside a string, when you don't want to use regex.... because node.js doesn't respect the non-standardized 'g' for non-regex
#
exports.replaceAll = replaceAll = (string, from, to) ->
  if string.indexOf(from) isnt -1
    return replaceAll(string.replace(from, to), from, to)
  else 
    return string

#
# Returns a linux terminal clickable file link.
# The trick is to avoid spaces (and to not introduce other escape characters such as %2F via full URI encoding)
#
exports.terminalClickableFileLink = (string) ->
  return """file://#{process.cwd()}/#{replaceAll(string, ' ', '%20')}"""