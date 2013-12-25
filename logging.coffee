# This coloring is terminal color based. 
# It doesn't work for the browser console. For browser console solutions (which are all based on css) 
# see http://stackoverflow.com/questions/7505623/colors-in-javascript-console/13017382.
# It's easy to create a function that provides the same API for both....

tty = {
  green:    '\x1b[32m'
  red  :    '\x1b[31m'  
  yellow:   '\x1b[33m'  
  blue:     '\x1b[36m'  
  endColor: '\x1b[0m'
}

exports.logGreen  = (text) -> console.log(tty.green + text + tty.endColor)
exports.logYellow = (text) -> console.log(tty.yellow + text + tty.endColor)
exports.logRed    = (text) -> console.log(tty.red + text + tty.endColor)
exports.logBlue  = (text) -> console.log(tty.blue + text + tty.endColor)

# See more terminal codes at if in need of more styles:
# https://github.com/Marak/colors.js/blob/master/colors.js 
# https://github.com/Marak/colors.js                       