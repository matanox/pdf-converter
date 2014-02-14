#
# Status: shaky
#
# Detail: The interaction has become a bit shaky as of integrating touch support.
#         The mouse and touch models are not really equivalent, and also present 
#         different idiosyncracies each.
#
#         Touch may also invoke mouse events, and the exact cases and order of events
#         may be quite browser and mobile operating system specific.
#
#         E.g. a quick touch may actually invoke a click event, so the two event models
#         are a bit interwined.
#
#         Cool and useful remote debugging can be accomplished using http://jsconsole.com/
#         Very basic simulation for confirming browser behavior can be carried out by something like 
#         http://patrickhlauke.github.io/touch/tests/event-listener.html or by forking it to
#         resemble a less minimal page.
#
# Note:   Behavior when emulating touch events on Chrome desktop's is the most quirky, probably
#         due to some interaction between touch and mouse events during emulation, which
#         may change in the next version of Chrome anyway.
#
# Bug:    Seems to stop working in iOS5 Safari after few marks.
#
# Missing touch features:
#  
#   This currently blocks the swipe-to-scroll behavior.
#   Blocking other built-in gesture recognition is good, but up/down scrolling
#   is imperative.
#
# 
# Recommendation: 
#    
#   Reorder functions per event model and clean up commented out code, 
#   before making any incremental change or addition.
#


remove = (node) ->
  node.parentNode.removeChild node

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
  inTouch     = false
  dragElements = new Array()  

  fluffChooser = null

  logDrag = () -> 
    console.log leftDown
    console.log rightDown
    console.log leftDrag
    console.log rightDrag

  Color = net.brehaut.Color
  baseMarkColor = Color('#FFB068')
  noColor = Color('rgba(0, 0, 0, 0)')

  mark = (elements, type) ->
    #console.dir elements
    for i in [Math.min.apply(null, elements)..Math.max.apply(null, elements)]

      element = document.getElementById(i)
      currentCssBackground = window.getComputedStyle(element, null).getPropertyValue('background-color')
      if currentCssBackground?
        #console.log(currentCssBackground)
        currentColor = Color().fromObject(currentCssBackground)
      else
        currentColor = noColor

      switch type

        when 'on'
          if currentColor.toCSSHex() is noColor.toCSSHex() 
            newColor = baseMarkColor
          else
            newColor = currentColor.darkenByRatio(0.1)
          element.style.backgroundColor = newColor.toCSS()

        when 'off'
          switch currentColor.toCSSHex() 
            when baseMarkColor.toCSSHex() 
              newColor = noColor
              element.style.backgroundColor = newColor.toCSS()
            when noColor.toCSSHex()
              # do nothing
            else
              newColor = currentColor.lightenByRatio(0.1)
              element.style.setProperty('background-color', newColor.toCSS())
  
    ###
    # Further highlight more the words actually hovered,
    # but not those that were only part of the selected range
    for element in elements
      document.getElementById(element).style.background = '#FAAC58'
    ###
 

    
  buttonHtmlObsolete = """<div class="btn-group">
                    <button type="button" class="btn btn-primary btn-lg">Primary</button>
                    <button type="button" class="btn btn-primary btn-lg dropdown-toggle" data-toggle="dropdown">
                      <span class="caret"></span>
                      <span class="sr-only">Toggle Dropdown</span>
                    </button>
                    <ul class="dropdown-menu" role="menu">
                      <li><a href="#">Action</a></li>
                      <li><a href="#">Another action</a></li>
                      <li><a href="#">Something else here</a></li>
                      <li class="divider"></li>
                      <li><a href="#">Separated link</a></li>
                    </ul>
                  </div>"""


  buttonGroupHtmlOld = """<div class="panel panel-default">
                         <div class="panel-heading">What did you just mark?</div>
                         <div class="panel-body">
                           <p>Help clean up this document by picking which category below does it belong to.</p>
                         </div>
                         <div class="list-group">
                           <a href="#" class="list-group-item">Journal name</a>
                           <a href="#" class="list-group-item">Institution</a>
                           <a href="#" class="list-group-item">Author</a>                              
                           <a href="#" class="list-group-item">Contact details</a>                              
                           <a href="#" class="list-group-item">Author description</a>                              
                           <a href="#" class="list-group-item">Classification</a>                              
                           <a href="#" class="list-group-item">Article ID</a>                              
                           <a href="#" class="list-group-item">List of keywords</a>
                           <a href="#" class="list-group-item">Advertisement</a>                              
                           <a href="#" class="list-group-item">History (received, pubslished dates etc)</a>                                                            
                           <a href="#" class="list-group-item">Copyright and permissions</a>                              
                           <a href="#" class="list-group-item">Document type description (e.g. 'Research Article')</a>                              
                           <a href="#" class="list-group-item">Not sure / other</a>                              
                         </div>
                       </div>"""

  buttonGroupHtml = """<div class="panel panel-default">
                         <div class="panel-heading">What did you just mark?</div>
                         <div class="panel-body">
                           <p>Help clean up this document by picking which category below does it belong to.</p>
                         </div>
                         <div class="btn-group-vertical">
                           <button type="button"  class="btn btn-default">Journal name</button>
                           <button type="button"  class="btn btn-default">Institution</button>
                           <button type="button"  class="btn btn-default">Author</button>      
                           <div class="btn-group open">
                            <button type="button" id="btnGroupVerticalDrop1" type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
                             Author
                              <span class="caret"></span>
                            </button>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="btnGroupVerticalDrop1">
                                <li><a >Author Name</a></li>
                                <li><a >Author Description</a></li>
                              </ul>
                            </div>            
                           <button type="button"  class="btn btn-default">Contact details</button>                              
                           <button type="button"  class="btn btn-default">Author description</button>                              
                           <button type="button"  class="btn btn-default">Classification</button>                              
                           <button type="button"  class="btn btn-default">Article ID</button>                              
                           <button type="button"  class="btn btn-default">List of keywords</button>
                           <button type="button"  class="btn btn-default">Advertisement</button>                              
                           <button type="button"  class="btn btn-default">History (received, pubslished dates etc)</button>                                                            
                           <button type="button"  class="btn btn-default">Copyright and permissions</button>                              
                           <button type="button"  class="btn btn-default">Document type description (e.g. 'Research Article')</button>                              
                           <button type="button"  class="btn btn-default">Not sure / other</button>                              
                         </div>
                       </div>"""




  addElement = (html, atElement, horizontalStart, cssClass) ->
        
    injectionPoint = document.getElementById(atElement)
    newElem = document.createElement('div')
    newElem.className = cssClass if classCss?
    newElem.innerHTML = html
    horizontalStart -= (injectionPoint.getBoundingClientRect().top + window.scrollY)
    newElem.style.setProperty('margin-top', horizontalStart + 'px')
    injectionPoint.appendChild(newElem)  
    newElem

  fluffChooserDisplay = (state, elements) ->
    #addElement(buttonHtml, 'top-bar', 'btn-group')
    switch state
      when 'show'
        if fluffChooser?  # first off remove if already visible
          fluffChooserDisplay('hide', elements)

        downMost  = 100000
        topBorder = 100000

        for element in elements
          rectangle = document.getElementById(element).getBoundingClientRect()
          #console.log rectangle.top + window.scrollY
          if rectangle.top + window.scrollY < topBorder then topBorder = rectangle.top + window.scrollY
          if rectangle.bottom + window.scrollY < downMost then downMost = rectangle.bottom + window.scrollY      
          #console.log topBorder
        fluffChooser = addElement(buttonGroupHtml, 'left-col', topBorder)
      when 'hide'
        fluffChooser.parentNode.removeChild(fluffChooser)
        console.log 'removing fluffchooser'
        fluffChooser = null
      when 'verifyHidden'
        if fluffChooser?
          fluffChooserDisplay('hide')

  endDrag = ->
    container.removeEventListener "mousemove", mousemoveHandler, false
    #container.removeEventListener "touchmove", touchmoveHandler, false
    #container.removeEventListener "touchend", page.ontouchend, false
      
    inDrag      = false
    inDrabMaybe = false
    console.log "drag ended"
    if dragElements.length > 0
      
      console.log 'inTouch is ' + inTouch

      if inTouch
        inTouch = false
        mark(dragElements.unique(), 'on')
        #fluffChooserDisplay('show', dragElements.unique())
        return       

      if leftDrag
        leftDrag = false
        mark(dragElements.unique(), 'on')
        fluffChooserDisplay('show', dragElements.unique())

      if rightDrag
        rightDrag = false
        mark(dragElements.unique(), 'off')

      dragElements = new Array()




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
    if inDragMaybe  # only if mouse was moved after a click, then we are in a real 'drag situation'

      inDrag = true             

      if leftDown
        leftDrag = true
      if rightDown
        rightDrag = true

      console.log('dragging')
      inDragMaybe = false       # avoid superfluous condition recurence 

    if inDrag and (event.target isnt container)
      dragElements.push event.target.id

  touchmoveHandler = (event) ->
    console.log 'in touch move handler'
    for touch in event.touches
      #console.dir touch
      if touch.target isnt container
        #console.log 'in touch move: ' + touch.target.id + ' when ' + dragElements + ' on ' + event.timeStamp 
        #overElement = document.elementFromPoint(touch.pageX, touch.pageY)
        #console.log overElement
        #overElement = document.elementFromPoint(touch.screenX, touch.screenY)
        #console.log overElement
        overElement = document.elementFromPoint(touch.clientX, touch.clientY)
        console.log overElement

        if overElement
          console.log overElement.id
          dragElements.push overElement.id
    false


  contextmenuHandler = (event) ->

    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log "right-click event captured"
    console.log event.target
    fluffChooserDisplay('verifyHidden')

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
    fluffChooserDisplay('verifyHidden')
    
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
    console.log 'in mouse up'
    
    if event.button is 0 
      leftDown = false
    else 
      rightDown = false

    inDragMaybe = false   
    endDrag() if inDrag
    false

  page.ontouchend = (event) ->
    for touch in event.changedTouches
      #console.dir touch

      ###
      if touch.target isnt container
        dragElements.push touch.target.id
        console.log 'in touch end/cancel: ' + touch.target.id + ' when ' + dragElements + ' on ' + event.timeStamp 
        #console.dir dragElements 
      ###
    endDrag()

  page.ontouchcancel = (event) -> page.ontouchend(event)

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

  page.ontouchstart = (event) ->
    #event.preventDefault()
    #event.stopPropagation()
    #event.stopImmediatePropagation()
    #console.log "touch start event captured " + event.timeStamp
    #console.log event.target
    #console.log container

    if event.target isnt container
      inTouch = true
      ###
      #
      # 
      #
      for touch in event.changedTouches
        if touch.target isnt container
          console.log 'in touch start: ' + touch.target.id + ' when ' + dragElements + ' on ' + event.timeStamp 
          dragElements.push touch.target.id
      ###
  
    # console.log(event.target)
    false

  container.addEventListener("touchstart", page.ontouchstart, false)
  container.addEventListener("touchend", page.ontouchend, false)
  container.addEventListener("touchmove", touchmoveHandler, false)


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
# TODO: This may not unregister event listeners and therefore cause pre-reloaded code
#       being executed even after reload finished. 
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
