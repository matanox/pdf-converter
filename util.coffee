logging       = require './logging' 
# crepl = require 'coffee-script/lib/coffee-script/repl'

anySpaceChar = RegExp(/\s/)

# Regexes for any html character reference. E.g. &amp &lt, etc.
exports.htmlCharacterEntity = RegExp(/&.*\b;$/) # delimited with any non-word character (html 4)

exports.anySpaceChar = anySpaceChar

endsWith = (string, match) ->
  string.lastIndexOf(match) is string.length - match.length

exports.endsWith = endsWith

startsWith = (string, match) ->
  string.indexOf(match) is 0

exports.startsWith = startsWith

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
isAnyOf = (string, matches) ->
  matches.some((elem) -> elem.localeCompare(string, 'en-US') == 0)

exports.isAnyOf = isAnyOf

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
timelog = (timer, logger) ->
  #timer = timer + ' took'                                    # the timer string is also the message 
                                                              # it will log to the console when it ends.
                                                             
  unless timelog.timersLookup? then timelog.timersLookup = {} # init timers array only once
  
  if timelog.timersLookup[timer]?                             # is this timer already started?
    #console.timeEnd(timer)
    end = new Date()
    elapsed = (end.getTime() - timelog.timersLookup[timer])
    if logger?
      logger.info(timer + ' took: ' + elapsed + ' ms')
    else
      logging.log(timer + ' took: ' + elapsed + ' ms')

    delete timelog.timersLookup[timer]
    return elapsed

  else                                                        # or is it starting now?
    start = new Date()
    timelog.timersLookup[timer] = start.getTime()
    return null
    #console.time(timer)

  # We should later also send this data to an analytics engine or depo. 
  # or Apache Kafka or equivalents could be good for grabbing from the logs and/or queueing/transport
  
exports.timelog = timelog

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
