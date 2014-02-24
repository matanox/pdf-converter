// Generated by CoffeeScript 1.6.3
var css, logging, parseCssClasses, punctuation, util;

util = require('./util');

logging = require('./logging');

css = require('./css');

parseCssClasses = function(styleString) {
  var cssClasses, regex;
  regex = new RegExp("\\b\\S+?\\b", 'g');
  cssClasses = styleString.match(regex);
  return cssClasses;
};

exports.representNodes = function(domObject) {
  var handleNode, myObjects;
  myObjects = [];
  handleNode = function(domObject, stylesArray) {
    var inheritingStylesArray, object, styleString, styles, text, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = domObject.length; _i < _len; _i++) {
      object = domObject[_i];
      switch (object.type) {
        case 'tag':
          if (object.children != null) {
            if (stylesArray == null) {
              stylesArray = [];
            }
            inheritingStylesArray = (function() {
              var _j, _len1, _results1;
              _results1 = [];
              for (_j = 0, _len1 = stylesArray.length; _j < _len1; _j++) {
                styles = stylesArray[_j];
                _results1.push(styles);
              }
              return _results1;
            })();
            styleString = object.attribs['class'];
            if (styleString != null) {
              styles = parseCssClasses(styleString.toString());
              inheritingStylesArray.push(styles);
            }
            _results.push(handleNode(object.children, inheritingStylesArray));
          } else {
            _results.push(void 0);
          }
          break;
        case 'text':
          if (object.data !== '\n') {
            text = object.data;
            _results.push(myObjects.push({
              text: text,
              stylesArray: stylesArray
            }));
          } else {
            _results.push(void 0);
          }
          break;
        default:
          _results.push(void 0);
      }
    }
    return _results;
  };
  handleNode(domObject);
  return myObjects;
};

punctuation = [',', ':', ';', '.', ')'];

exports.tokenize = function(nodeWithStyles) {
  var filterEmptyString, splitByPrefixChar, splitBySuffixChar, token, tokenize, tokens, _i, _len;
  splitBySuffixChar = function(inputTokens) {
    var endsWithPunctuation, text, token, tokens, _i, _len;
    punctuation = [',', ':', ';', '.', ')'];
    tokens = [];
    for (_i = 0, _len = inputTokens.length; _i < _len; _i++) {
      token = inputTokens[_i];
      switch (token.metaType) {
        case 'delimiter':
          tokens.push(token);
          break;
        case 'regular':
          text = token.text;
          endsWithPunctuation = util.endsWithAnyOf(text, punctuation);
          if (endsWithPunctuation && (text.length > 1)) {
            if (!(util.lastChar(text) === ';' && /.?&.*\b;$/.test(text))) {
              tokens.push({
                'metaType': 'regular',
                'text': text.slice(0, text.length - 1),
                'stylesArray': token.stylesArray
              });
              tokens.push({
                'metaType': 'regular',
                'text': text.slice(text.length - 1),
                'stylesArray': token.stylesArray
              });
            } else {
              tokens.push(token);
            }
          } else {
            tokens.push(token);
          }
          break;
        default:
          throw 'Invalid token meta-type encountered';
          util.logObject(token);
      }
    }
    return tokens;
  };
  splitByPrefixChar = function(inputTokens) {
    var startsWithPunctuation, text, token, tokens, _i, _len;
    punctuation = ['('];
    tokens = [];
    for (_i = 0, _len = inputTokens.length; _i < _len; _i++) {
      token = inputTokens[_i];
      switch (token.metaType) {
        case 'delimiter':
          tokens.push(token);
          break;
        case 'regular':
          text = token.text;
          startsWithPunctuation = util.startsWithAnyOf(text, punctuation);
          if (startsWithPunctuation && (text.length > 1)) {
            tokens.push({
              'metaType': 'regular',
              'text': text.slice(0, 1),
              'stylesArray': token.stylesArray
            });
            tokens.push({
              'metaType': 'regular',
              'text': text.slice(1),
              'stylesArray': token.stylesArray
            });
          } else {
            tokens.push(token);
          }
          break;
        default:
          throw "Invalid token meta-type encountered";
          util.logObject(token);
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
  tokenize = function(nodeWithStyles) {
    var char, i, insideDelimiter, insideWord, string, tokens, withStyles, word, _i, _ref;
    withStyles = function(token) {
      token.stylesArray = nodeWithStyles.stylesArray;
      return token;
    };
    string = nodeWithStyles.text;
    insideWord = false;
    insideDelimiter = false;
    tokens = [];
    if (string.length === 0) {
      return [];
    }
    for (i = _i = 0, _ref = string.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      char = string.charAt(i);
      if (util.isAnySpaceChar(char)) {
        if (insideWord) {
          tokens.push(withStyles({
            'metaType': 'regular',
            'text': word
          }));
          insideWord = false;
        }
        if (!insideDelimiter) {
          tokens.push(withStyles({
            'metaType': 'delimiter'
          }));
          insideDelimiter = true;
        }
      } else {
        if (insideDelimiter) {
          insideDelimiter = false;
        }
        if (insideWord) {
          word = word.concat(char);
        } else {
          word = char;
          insideWord = true;
        }
      }
    }
    if (insideWord) {
      tokens.push(withStyles({
        'metaType': 'regular',
        'text': word
      }));
    }
    return tokens;
  };
  tokens = tokenize(nodeWithStyles);
  tokens = splitBySuffixChar(tokens);
  tokens = splitByPrefixChar(tokens);
  for (_i = 0, _len = tokens.length; _i < _len; _i++) {
    token = tokens[_i];
    if (token.metaType === 'regular') {
      if (token.text.length === 0) {
        throw "error in tokenize";
      }
    }
  }
  return tokens;
};

exports.buildOutputHtml = function(tokens, finalStyles, docLogger) {
  var convertToHtml, plainText, x, _i, _len;
  convertToHtml = function(token, moreStyle) {
    var style, stylesString, text, val, _ref;
    stylesString = '';
    _ref = token.finalStyles;
    for (style in _ref) {
      val = _ref[style];
      stylesString = stylesString + style + ':' + val + '; ';
    }
    if (moreStyle != null) {
      stylesString = stylesString + ' ' + moreStyle;
    }
    if (stylesString.length > 0) {
      stylesString = 'style=\"' + stylesString + '\"';
      if (token.metaType === 'regular') {
        text = token.text;
      } else {
        text = ' ';
      }
      return "<span " + stylesString + " id=\"" + x.id + "\">" + text + "</span>";
    } else {
      docLogger.warn('token had no styles attached to it when building output. token text: ' + token.text);
      return "<span>" + token.text + "</span>";
    }
  };
  util.timelog('Serialization to output');
  for (_i = 0, _len = tokens.length; _i < _len; _i++) {
    x = tokens[_i];
    if (x.metaType === 'regular') {
      switch (x.paragraph) {
        case 'closer':
          x.text = x.text + '<br /><br />';
          plainText = plainText + convertToHtml(x);
          break;
        case 'opener':
          plainText = plainText + convertToHtml(x, 'display: inline-block; text-indent: 2em;');
          break;
        default:
          plainText = plainText + convertToHtml(x);
      }
    } else {
      plainText = plainText + convertToHtml(x);
    }
  }
  util.timelog('Serialization to output', docLogger);
  return plainText;
};
