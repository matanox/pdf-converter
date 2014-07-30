#
# Obsolete by util.coffee's equivalent
#

# Till something better comes along, ride the crude node.js timer logging feature
# TODO: this needs to be replaced with a browser-compatible implementation

exports.start = (label) -> console.time(label + ' took')
exports.end = (label) -> console.timeEnd(label + ' took')  
