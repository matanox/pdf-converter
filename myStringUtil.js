

exports.endsWith = function(string, match){
	return string.indexOf(match) == string.length - match.length
}

exports.startsWith = function(string, match){
	return string.indexOf(match) == 0
}

exports.contains = function(string, match){
	return string.indexOf(match) != -1
}

exports.getSimpleDivContent = function(xmlNode){
	// assumes there are no nested divs inside xmlNode
	xmlNode.slice(xmlNode.match('<div.*?>').length)  // remove opening div tag
	xmlNode.slice(0, xmlNode.length-'</div>'.length) // remove closing div tag
}
