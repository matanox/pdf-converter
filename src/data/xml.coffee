logging    = require '../util/logging' 
util       = require '../util/util'

#
# JATS xml building utilities - 
# taking a simple approach of building it from strings, not through a fancy XML api for now
#

exports.wrapAsJats = (content) ->
  """<?xml version="1.0" encoding="UTF-8"?><article xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mml="http://www.w3.org/1998/Math/MathML"><body>"""  + content +  "</body></article>"

XMLescaping = [{from: "&",  to: "&amp;"},
               {from: "<",  to: "&lt;"},
               {from: ">",  to: "&gt;"},
               {from: "\"\"", to: "&quot;"}, # the backslash char double-escaped... alas the joy of using regular expressions...
               {from: "'",  to: "&apos;"}]

exports.escape = (string) ->
  for e in XMLescaping
    string = string.replace(new RegExp(e.from, 'g'), e.to)
  return string

signal = exports.signal = (type, action, paramObj) ->
  switch type 
    when 'paragraph'
      if action is 'opener' then return '<p>'
      if action is 'closer' then return '</p>'

    when 'section'  
      if action is 'opener' then return """<sec sec-type="#{paramObj.sectionType}"><title>#{paramObj.sectionName}</title>"""
      if action is 'closer' then return '</sec>'

exports.init = ''


