//
// Attaches event handlers to the page called for
//

//
// Optional TODO: 
// The event window.onload is a bit late - text can be manipulated before it fires, 
// but alas document.onload doesn't work in Chrome. So to set up the events earlier:
//   Can attach all these events directly inside the hookPoint element in the html,
//   or introduce something like (or leaner than) jquery 
//

window.onload = function()
{
  console.log('Setting up events...');

  var hookPoint = document.getElementById('hookPoint')

/*
  eventCapture = function(event) 
  {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log(event.type + ' event captured for element ' + JSON.stringify(event.target));
    return false
  }

  hookPoint.oncontextmenu = eventCapture
*/

  remove = function (node)
  {
    node.parentNode.removeChild(node)
  }

  hookPoint.oncontextmenu = function (event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log('right-click event captured')
    console.log(event.target)

    remove(event.target)

    return false
  }


  hookPoint.onclick = function (event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log('click event captured')
    console.log(event.target)
    return false
  }

  hookPoint.ondblclick = function (event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log('double-click event captured')
    console.log(event.target)
    return false
  }

  // disable word selection on double click
  // see http://javascript.info/tutorial/mouse-events#preventing-selection
  hookPoint.onselectstart= function (event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log('select-start event captured')
    console.log(event.target)
    return false
  } // for IE

  hookPoint.onmousedown=function (event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    console.log('mouse-down event captured')
    console.log(event.target)
    return false
  } // for non-IE
}