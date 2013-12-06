

exports.endsWith = function(string, match){
	return string.indexOf(match) == string.length - match.length
}

exports.startsWith = function(string, match){
	return string.indexOf(match) == 0
}

exports.contains = function(string, match){
	return string.indexOf(match) != -1
}

//
// Extracts the text of a div element
//
exports.simpleGetDivContent = function(xmlNode){
	// assumes there are no nested divs inside xmlNode
	
	// console.log(xmlNode.length)
	// console.log('</div>'.length)
	
	content = xmlNode.slice(0, xmlNode.length - '</div>'.length) // remove closing div tag
	
	// console.log(content)
	// console.log(content.match('>'))
	
	content = content.slice(content.indexOf('>')+1)  // remove opening div tag

	console.log(xmlNode)
	console.log(content + '\n' + '\n')

	return content
}

