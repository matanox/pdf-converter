// Generated by CoffeeScript 1.4.0
var clone, contains, endsWith, isAnyOf, startsWith;

endsWith = function(string, match) {
  return string.lastIndexOf(match) === string.length - match.length;
};

exports.endsWith = endsWith;

startsWith = function(string, match) {
  return string.indexOf(match) === 0;
};

exports.startsWith = startsWith;

contains = function(string, match) {
  return string.indexOf(match) !== -1;
};

exports.strip = function(string, prefix, suffix) {
  if (!startsWith(string, prefix)) {
    throw "Cannot strip string of the supplied prefix";
  }
  if (!endsWith(string, suffix)) {
    throw "Cannot strip string of the supplied suffix";
  }
  return string.slice(string.indexOf(prefix) + prefix.length, string.lastIndexOf(suffix));
};

isAnyOf = function(string, matches) {
  return matches.some(function(elem) {
    return elem.localeCompare(string, 'en-US') === 0;
  });
};

exports.isAnyOf = isAnyOf;

exports.endsWithAnyOf = function(string, matches) {
  var trailingChar;
  trailingChar = string.charAt(string.length - 1);
  if (!isAnyOf(trailingChar, matches)) {
    return false;
  }
  return trailingChar;
};

exports.startsWithAnyOf = function(string, matches) {
  var char;
  char = string.charAt(0);
  if (!isAnyOf(char, matches)) {
    return false;
  }
  return char;
};

exports.parseElementText = function(xmlNode) {
  var content;
  content = xmlNode.substr(0, xmlNode.length - "</div>".length);
  content = content.slice(content.indexOf(">") + 1);
  return content;
};

exports.logObject = function(obj) {
  return console.log(JSON.stringify(obj, null, 2));
};

exports.objectViolation = function(errorMessage) {
  var error;
  error = new Error(errorMessage);
  console.log(error.stack);
  throw error;
};

exports.anySpaceChar = RegExp(/\s/);

clone = function(obj) {
  var key, newInstance;
  if (!(obj != null) || typeof obj !== 'object') {
    return obj;
  }
  newInstance = {};
  for (key in obj) {
    newInstance[key] = clone(obj[key]);
  }
  return newInstance;
};

exports.clone = clone;
