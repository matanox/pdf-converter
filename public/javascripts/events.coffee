# http://coffeescriptcookbook.com/chapters/arrays/removing-duplicate-elements-from-arrays
Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

#
# Load prerequisite library via ajax, and pass along to our code after it has been added
# to the page context. Uses a small trick - see comment within.
#
startAfterPrerequisites = () ->
  ajaxRequest = new XMLHttpRequest()

  ajaxRequest.onreadystatechange = () ->
    if ajaxRequest.readyState is 4
      if ajaxRequest.status is 200
        console.log 'Ajax fetching javascript succeeded.'
        console.log 'Proceeding to start processing after fetched javascript will have been fully loaded'

        script = document.createElement("script")
        script.type = "text/javascript"
        inject = ajaxRequest.responseText + '\n' + 'go()'  # appending a call to our code to the original script
        script.innerHTML = inject
        document.getElementsByTagName("head")[0].appendChild(script)
      else
        console.error 'Failed loading prerequisite library via ajax. Aborting...'

  #ajaxRequest.open('GET', 'javascripts/external/superagent.js', true)
  ajaxRequest.open('GET', 'javascripts/external/color.js', true)  # from https://github.com/brehaut/color-js
  ajaxRequest.send(null)

#
# Attaches event handlers to the page called for
#
#
# Optional TODO: 
# The event window.onload is a bit late - text can be manipulated before it fires, 
# but alas document.onload doesn't work in Chrome. So to set up the events earlier:
#   Can attach all these events directly inside the hookPoint element in the html,
#   or introduce something like (or leaner than) jquery. Or, maybe no need to wait 
#   for the entire page to load as long as the necessary hookpoint has already 
#   been created!
#
startEventMgmt = () ->

  console.log "Setting up events..."
  container = document.getElementById('hookPoint')
  page = document.body

  leftDown    = false
  rightDown   = false
  leftDrag    = false
  rightDrag   = false
  inDragMaybe = false
  inDrag      = false
  dragElements = new Array()

  logDrag = () -> 
    console.log leftDown
    console.log rightDown
    console.log leftDrag
    console.log rightDrag

  Color = net.brehaut.Color
  baseMarkColor = Color('#FFB068')
  noColor = Color('rgba(0, 0, 0, 0)')

  mark = (elements, type) ->
    for i in [Math.min.apply(null, elements)..Math.max.apply(null, elements)]

      element = document.getElementById(i)
      currentCssBackground = window.getComputedStyle(element, null).getPropertyValue('background-color')
      if currentCssBackground?
        console.log(currentCssBackground)
        currentColor = Color().fromObject(currentCssBackground)
      else
        currentColor = noColor

      switch type

        when 'on'
          if currentColor.toCSSHex() is noColor.toCSSHex() 
            newColor = baseMarkColor
          else
            newColor = currentColor.darkenByRatio(0.05)
          element.style.backgroundColor = newColor.toCSS()

        when 'off'
          switch currentColor.toCSSHex() 
            when baseMarkColor.toCSSHex() 
              newColor = noColor
              element.style.backgroundColor = newColor.toCSS()
            when noColor.toCSSHex()
              # do nothing
            else
              newColor = currentColor.lightenByRatio(0.05)
              element.style.setProperty('background-color', newColor.toCSS())
    
    ###
    # Further highlight more the words actually hovered,
    # but not those that were only part of the selected range
    for element in elements
      document.getElementById(element).style.background = '#FAAC58'
    ###
    dragElements = new Array()

  endDrag = ->
    container.removeEventListener "mousemove", mousemoveHandler, false
    inDrag      = false
    inDrabMaybe = false
    console.log "drag ended"
    if dragElements.length > 0
      if leftDrag
        leftDrag = false
        mark(dragElements.unique(), 'on')
      if rightDrag
        rightDrag = false
        mark(dragElements.unique(), 'off')



  mousemoveHandler = (event) ->
  
    #console.log('mouse move detected')
    #console.dir(event)
    #console.log(event.relatedTarget)
    #console.log(event.srcElement)
    #console.log(event.toElement)
    #console.log(event.target)
    #console.log(event.target.id) 
    #console.log inDragMaybe
    #console.log inDrag
    #logDrag()
    if inDragMaybe is true  # only if mouse was moved after a click, then we are in a real 'drag situation'

      inDrag = true             

      if leftDown
        leftDrag = true
      if rightDown
        rightDrag = true

      console.log('dragging')
      inDragMaybe = false       # avoid superfluous condition recurence 

    if inDrag and (event.target isnt container)
      dragElements.push event.target.id

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

    #remove event.target unless event.target is event.currentTarget
    false

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
    #console.log inDragMaybe
    #console.log inDrag

    if event.button is 0 
      leftDown = false
    else 
      rightDown = false

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
    #console.log event.target
    #console.log container
    if event.button is 0
      leftDown = true
    else
      rightDown = true

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

go = () ->
  window.onload = () -> startEventMgmt()

startAfterPrerequisites()

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
