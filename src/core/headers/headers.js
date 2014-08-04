// Generated by CoffeeScript 1.6.3
var dataWriter, expected, isTitleNumeral, logging, noHeadersDocs, separateness, tripleIterator;

dataWriter = require('../../data/dataWriter');

logging = require('../../util/logging');

expected = require('./expected');

noHeadersDocs = 0;

tripleIterator = function(tokens, func) {
  var curr, i, next, prev, _results;
  i = 1;
  _results = [];
  while (i < tokens.length - 1) {
    prev = tokens[i - 1];
    curr = tokens[i];
    next = tokens[i + 1];
    func(prev, curr, next);
    _results.push(i = i + 1);
  }
  return _results;
};

isTitleNumeral = function(text) {
  if (!isNaN(parseInt(text.charAt(0)))) {
    return true;
  }
  return false;
};

separateness = function(prev, curr) {
  logging.logBlue("separateness test");
  logging.logBlue("size: " + curr.finalStyles['font-size'] + " font: " + curr.finalStyles['font-family'] + " v.s. \nsize: " + prev.finalStyles['font-size'] + " font: " + prev.finalStyles['font-family'] + " ");
  if (curr.finalStyles['font-size'] !== prev.finalStyles['font-size']) {
    return true;
  }
  if (curr.finalStyles['font-family'] !== prev.finalStyles['font-family']) {
    return true;
  }
  return false;
};

module.exports = function(name, tokens) {
  var anyFound, headers, regularTokens;
  anyFound = false;
  headers = [];
  regularTokens = tokens.filter(function(token) {
    return token.metaType === 'regular';
  });
  tripleIterator(regularTokens, function(prev, curr, next) {
    var _ref;
    if (expected.indexOf(curr.text) === -1) {
      return;
    }
    if ((_ref = curr["case"]) !== 'upper' && _ref !== 'title') {
      return;
    }
    if (curr.paragraphOpener) {
      if (separateness(prev, curr)) {
        anyFound = true;
        dataWriter.write(name, 'headers', "token id " + curr.id + ": " + curr.text + " (paragraph opener)", true);
        return;
      }
    }
    if (isTitleNumeral(prev.text)) {
      if (prev.paragraphOpener) {
        anyFound = true;
        dataWriter.write(name, 'headers', "token id " + curr.id + ": " + curr.text + " (following numeral paragraph opener)", true);
      }
    }
  });
  if (!anyFound) {
    logging.logRed("no headers detected for " + name + " (" + noHeadersDocs + " total)");
    return noHeadersDocs += 1;
  }
};
