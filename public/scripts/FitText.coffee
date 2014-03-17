#!	
#* FitText.js 1.0 jQuery free version
#*
#* Copyright 2011, Dave Rupert http://daverupert.com 
#* Released under the WTFPL license 
#* http://sam.zoy.org/wtfpl/
#* Modified by Slawomir Kolodziej http://slawekk.info
#*
#* Date: Tue Aug 09 2011 10:45:54 GMT+0200 (CEST)
#
(->
  css = (el, prop) ->
    (if window.getComputedStyle then getComputedStyle(el).getPropertyValue(prop) else el.currentStyle[prop])

  addEvent = (el, type, fn) ->
    if el.addEventListener
      el.addEventListener type, fn, false
    else
      el.attachEvent "on" + type, fn

  extend = (obj, ext) ->
    for key of ext
      obj[key] = ext[key]  if ext.hasOwnProperty(key)
    obj

  window.fitText = (el, kompressor, options) ->
    settings = extend(
      minFontSize: -1 / 0
      maxFontSize: 1 / 0
    , options)
    fit = (el) ->
      compressor = kompressor or 1
      resizer = ->
        el.style.fontSize = Math.max(Math.min(el.clientWidth / (compressor * 10), parseFloat(settings.maxFontSize)), parseFloat(settings.minFontSize)) + "px"

      
      # Call once to set.
      resizer()
      
      # Bind events
      # If you have any js library which support Events, replace this part
      # and remove addEvent function (or use original jQuery version)
      addEvent window, "resize", resizer

    if el.length
      i = 0

      while i < el.length
        fit el[i]
        i++
    else
      fit el
    
    # return set of elements
    el
)()
