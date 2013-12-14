// Generated by CoffeeScript 1.4.0
var parseCssClasses, util;

util = require('./util');

exports.removeOuterDivs = function(string) {
  var regex;
  regex = new RegExp('<div((?!div).)*</div>', 'g');
  return string.match(regex);
};

parseCssClasses = function(xmlNode) {
  var cssClasses, cssClassesString, regex;
  regex = new RegExp("<div class=\".*?\"", 'g');
  cssClassesString = xmlNode.match(regex);
  cssClassesString = util.strip(cssClassesString[0], "<div class=\"", "\"");
  regex = new RegExp("\\b\\S+?\\b", 'g');
  cssClasses = cssClassesString.match(regex);
  return cssClasses;
};

exports.representDiv = function(xmlNode) {
  var styles, text;
  text = util.parseElementText(xmlNode);
  styles = parseCssClasses(xmlNode);
  return {
    text: text,
    styles: styles
  };
};

exports.stripSpanWrappers = function(div) {
  var spanBegin, spanEnd;
  spanBegin = new RegExp('<span.*?>', 'g');
  spanEnd = new RegExp('</span>', 'g');
  div.text = div.text.replace(spanBegin, '');
  return div.text = div.text.replace(spanEnd, '');
};

exports.tokenize = function(styledText) {
  var filterEmptyString, spaceDelimitedTokens, splitByPrefixChar, splitBySuffixChar, token, tokens, tokensWithStyle;
  splitBySuffixChar = function(spaceDelimitedTokens) {
    var endsWithPunctuation, punctuation, token, tokens, _i, _len;
    punctuation = [',', ':', ';', '.', ')'];
    tokens = [];
    for (_i = 0, _len = spaceDelimitedTokens.length; _i < _len; _i++) {
      token = spaceDelimitedTokens[_i];
      endsWithPunctuation = util.endsWithAnyOf(token, punctuation);
      if (!endsWithPunctuation) {
        tokens.push(token);
      } else {
        tokens.push(token.slice(0, token.length - 1));
        tokens.push(token.slice(token.length - 1));
      }
    }
    return tokens;
  };
  splitByPrefixChar = function(spaceDelimitedTokens) {
    var punctuation, startsWithPunctuation, token, tokens, _i, _len;
    punctuation = ['('];
    tokens = [];
    for (_i = 0, _len = spaceDelimitedTokens.length; _i < _len; _i++) {
      token = spaceDelimitedTokens[_i];
      startsWithPunctuation = util.startsWithAnyOf(token, punctuation);
      if (!startsWithPunctuation) {
        tokens.push(token);
      } else {
        tokens.push(token.slice(0, 1));
        tokens.push(token.slice(1));
      }
    }
    return tokens;
  };
  filterEmptyString = function(tokens) {
    var filtered, token, _i, _len;
    filtered = [];
    for (_i = 0, _len = tokens.length; _i < _len; _i++) {
      token = tokens[_i];
      if (token.length > 0) {
        filtered.push(token);
      }
    }
    return filtered;
  };
  spaceDelimitedTokens = styledText.text.split(/\s/);
  spaceDelimitedTokens = filterEmptyString(spaceDelimitedTokens);
  tokens = splitBySuffixChar(spaceDelimitedTokens);
  tokens = splitByPrefixChar(tokens);
  tokensWithStyle = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = tokens.length; _i < _len; _i++) {
      token = tokens[_i];
      _results.push({
        'text': token,
        'styles': styledText.styles
      });
    }
    return _results;
  })();
  return tokensWithStyle;
};
