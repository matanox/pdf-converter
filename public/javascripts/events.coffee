#
# Attaches event handlers to the page called for
#

#
# Optional TODO: 
# The event window.onload is a bit late - text can be manipulated before it fires, 
# but alas document.onload doesn't work in Chrome. So to set up the events earlier:
#   Can attach all these events directly inside the hookPoint element in the html,
#   or introduce something like (or leaner than) jquery 
#

# http://coffeescriptcookbook.com/chapters/arrays/removing-duplicate-elements-from-arrays
Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

inDrag = false
dragElements = new Array()

mark = (elements) ->
  for i in [Math.min.apply(null, elements)..Math.max.apply(null, elements)]
    document.getElementById(i).style.background = '#FAAB58'
  for element in elements
    document.getElementById(element).style.background = '#FAAC58'
  dragElements = new Array()

endDrag = ->
  hookPoint.removeEventListener "mousemove", mousemoveHandler, false
  inDrag = false
  console.log "drag ended"
  #console.dir dragElements.unique()
  mark(dragElements.unique())
  #ragElements = new Array()

mousemoveHandler = (event) ->
  
  #console.log('mouse move detected')
  #console.dir(event)
  #console.log(event.relatedTarget)
  #console.log(event.srcElement)
  #console.log(event.toElement)
  #console.log(event.target)
  
  #console.log(event.target.id) 
  if (inDrag is true) and (event.target.id isnt 'hookPoint')
    dragElements.push event.target.id

window.onload = ->
  console.log "Setting up events..."
  hookPoint = document.getElementById("hookPoint")
  container = document.body
  remove = (node) ->
    node.parentNode.removeChild node

  hookPoint.oncontextmenu = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "right-click event captured"
    console.log event.target
    
    # We avoid taking action on the top element where the listener was registered.
    # target is the element invoked on, currentTarget is the element where the 
    # event listener was registered. In a DOM hierarcy of objects, they are 
    # (typically) not the same element.
    remove event.target  unless event.target is event.currentTarget
    false

  hookPoint.onclick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "click event captured"
    
    #console.log(event.target)
    false

  hookPoint.ondblclick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "double-click event captured"
    
    #console.log(event.target)
    false

  container.onmouseup = (event) ->
    
    #event.preventDefault()
    #event.stopPropagation()
    #event.stopImmediatePropagation()
    # console.log(event.target)
    # then this is the end of the drag..
    endDrag() if inDrag is true
    false

  # disable word selection on double click
  # for non-IE
  container.onmousedown = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "(mouse-down event captured. skipping listing the target object)"
    if (event.button is 0) and (event.target.id isnt 'hookPoint')
      inDrag = true
      hookPoint.addEventListener "mousemove", mousemoveHandler, false
    
    # console.log(event.target)
    false

  # disable word selection on double click
  # see http://javascript.info/tutorial/mouse-events#preventing-selection
  # for IE
  container.onselectstart = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "select-start event captured"
    
    #console.log(event.target)
    false

#
#  eventCapture = function(event) 
#  {
#    event.preventDefault()
#    event.stopPropagation()
#    event.stopImmediatePropagation()
#    console.log(event.type + ' event captured for element ' + JSON.stringify(event.target));
#    return false
#  }
#
#  hookPoint.oncontextmenu = eventCapture
#
