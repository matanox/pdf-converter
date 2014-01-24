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

leftDown    = false
inDragMaybe = false
inDrag      = false
dragElements = new Array()

mark = (elements) ->
  for i in [Math.min.apply(null, elements)..Math.max.apply(null, elements)]
    document.getElementById(i).style.background = '#FAA058'
  for element in elements
    document.getElementById(element).style.background = '#FAAC58'
  dragElements = new Array()

contextmenuHandler = (event) ->
  remove = (node) ->
    node.parentNode.removeChild node

  event.preventDefault()
  event.stopPropagation()
  event.stopImmediatePropagation()
  console.log "right-click event captured"
  console.log event.target

  # We avoid taking action on the top element where the listener was registered.
  # target is the element invoked on, currentTarget is the element where the 
  # event listener was registered. In a DOM hierarcy of objects, they are 
  # (typically) not the same element.
  remove event.target unless event.target is event.currentTarget
  false

startEventMgmt = () ->
  console.log "Setting up events..."
  container = document.getElementById('hookPoint')
  page = document.body

  endDrag = ->
    container.removeEventListener "mousemove", mousemoveHandler, false
    inDrag      = false
    inDrabMaybe = false
    console.log "drag ended"
    if dragElements.length > 0
      mark(dragElements.unique())

  mousemoveHandler = (event) ->
  
    #console.log('mouse move detected')
    #console.dir(event)
    #console.log(event.relatedTarget)
    #console.log(event.srcElement)
    #console.log(event.toElement)
    #console.log(event.target)
    #console.log(event.target.id) 

    if inDragMaybe is true
      inDrag = true             # only if mouse was moved after a click, then we are in a real 'drag situation'
      console.log('dragging')
      inDragMaybe = false       # avoid superfluous condition recurence 

    if inDrag and (event.target isnt container)
      dragElements.push event.target.id

  container.addEventListener("contextmenu", contextmenuHandler)

  container.onclick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "click event captured"
    
    #console.log(event.target)
    false

  container.ondblclick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "double-click event captured"
    
    #console.log(event.target)
    false

  page.onmouseup = (event) ->
    
    #event.preventDefault()
    #event.stopPropagation()
    #event.stopImmediatePropagation()
    # console.log(event.target)
    # then this is the end of the drag..
    if event.button is 0 then leftDown = false
    inDragMaybe = false   
    endDrag() if inDrag is true
    false

  # disable word selection on double click
  # for non-IE
  page.onmousedown = (event) ->
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "mouse-down event captured"
    #console.log event.button
    #console.log event.buttons
    if event.button is 0
      leftDown = true
      if event.target isnt container
        inDragMaybe = true
        container.addEventListener "mousemove", mousemoveHandler, false
    
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

window.onload = () -> startEventMgmt()

#
# For easier code iteration in the browser - just invoke this function from the browser console
# SECURITY: Remove this function in case reloading may have adverse effect on logic
#
reload = () ->
  script = document.createElement("script")
  script.type = "text/javascript"
  script.src = "javascripts/events.js"
  document.getElementsByTagName("head")[0].appendChild(script)
  startEventMgmt()
  console.log('reloaded')

enableContext = () ->
  document.getElementById("hookPoint").removeEventListener("contextmenu", contextmenuHandler)

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
#  container.oncontextmenu = eventCapture
#
