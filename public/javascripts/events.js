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

  hookPoint.oncontextmenu = function (evt) {
    evt.preventDefault()
    evt.stopPropagation()
    evt.stopImmediatePropagation()
    console.log('right-click event captured')
    console.log(evt.srcElement)
    return false
  }

  hookPoint.onclick = function (evt) {
    evt.preventDefault()
    evt.stopPropagation()
    evt.stopImmediatePropagation()
    console.log('click event captured')
    console.log(evt.srcElement)
    return false
  }

  hookPoint.ondblclick = function (evt) {
    evt.preventDefault()
    evt.stopPropagation()
    evt.stopImmediatePropagation()
    console.log('double-click event captured')
    console.log(evt.srcElement)
    return false
  }

  // disable word selection on double click
  // see http://javascript.info/tutorial/mouse-events#preventing-selection
  hookPoint.onselectstart= function (evt) {
    evt.preventDefault()
    evt.stopPropagation()
    evt.stopImmediatePropagation()
    console.log('select-start event captured')
    console.log(evt.srcElement)
    return false
  } // for IE

  hookPoint.onmousedown=function (evt) {
    evt.preventDefault()
    evt.stopPropagation()
    evt.stopImmediatePropagation()
    console.log('mouse-down event captured')
    console.log(evt.srcElement)
    return false
  } // for non-IE
}