// Generated by CoffeeScript 1.4.0
var cssParser, extractCssFileNames, extractCssProperties, serializeStyle, util;

cssParser = require('css-parse');

util = require('./util');

extractCssFileNames = function(string) {
  var cssFiles, linkStripper, prefix, regex, stylesheetElem, suffix;
  prefix = '<link rel="stylesheet" href="';
  suffix = '"/>';
  regex = new RegExp(prefix + '.*' + suffix, 'g');
  linkStripper = function(string) {
    return util.strip(string, prefix, suffix);
  };
  cssFiles = (function() {
    var _i, _len, _ref, _results;
    _ref = string.match(regex);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      stylesheetElem = _ref[_i];
      _results.push(linkStripper(stylesheetElem));
    }
    return _results;
  })();
  return cssFiles;
};

extractCssProperties = function(string) {
  var css, deconstruct, element, mediaScreenElements, regex, stylesArray;
  regex = new RegExp('[\\n|\\r]', 'g');
  string = string.replace(regex, "");
  regex = new RegExp('/\\*.*?\\*/', 'g');
  string = string.replace(regex, "");
  css = cssParser(string);
  mediaScreenElements = css.stylesheet.rules.filter(function(element) {
    return element.type === 'media' && element.media.indexOf('screen') !== -1;
  })[0].rules;
  stylesArray = css.stylesheet.rules.filter(function(element) {
    return !(element.type === 'media');
  });
  stylesArray = stylesArray.filter(function(element) {
    return !(element.type === 'keyframes');
  });
  stylesArray = stylesArray.concat(mediaScreenElements);
  deconstruct = function(element) {
    var filterProperties, name, obj, propertyObjectsArray, _i, _len, _ref;
    filterProperties = function(propertyObjectsArray) {
      var positionData, relevantStyles;
      relevantStyles = ['font-family', 'font-size', 'font-style', 'font-weight', 'word-spacing', 'line-height', 'color'];
      positionData = ['left', 'bottom'];
      propertyObjectsArray = propertyObjectsArray.filter(function(propertyPair) {
        return util.isAnyOf(propertyPair.property, relevantStyles.concat(positionData));
      });
      return propertyObjectsArray;
    };
    if (!(element.declarations[0] != null)) {
      return null;
    }
    (_ref = element.selectors, name = _ref[0]), propertyObjectsArray = element.declarations;
    propertyObjectsArray = filterProperties(propertyObjectsArray);
    if (propertyObjectsArray.length === 0) {
      return null;
    }
    if (name.charAt(0) !== '.') {
      return null;
    }
    for (_i = 0, _len = propertyObjectsArray.length; _i < _len; _i++) {
      obj = propertyObjectsArray[_i];
      delete obj.type;
    }
    return {
      name: name,
      propertyObjectsArray: propertyObjectsArray
    };
  };
  return ((function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = stylesArray.length; _i < _len; _i++) {
      element = stylesArray[_i];
      _results.push(deconstruct(element));
    }
    return _results;
  })()).filter(function(elem) {
    return elem != null;
  });
};

exports.simpleFetchStyles = function(rawHtml, path) {
  var array, cssFilePaths, file, name, rawCss, rawCsss, style, styles, stylesMap, stylesPerFile, _i, _j, _len, _len1;
  cssFilePaths = (function() {
    var _i, _len, _ref, _results;
    _ref = extractCssFileNames(rawHtml);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      name = _ref[_i];
      _results.push((function(name) {
        return path + name;
      })(name));
    }
    return _results;
  })();
  rawCsss = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = cssFilePaths.length; _i < _len; _i++) {
      file = cssFilePaths[_i];
      _results.push(fs.readFileSync(file).toString());
    }
    return _results;
  })();
  stylesPerFile = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = rawCsss.length; _i < _len; _i++) {
      rawCss = rawCsss[_i];
      _results.push(extractCssProperties(rawCss));
    }
    return _results;
  })();
  styles = [];
  for (_i = 0, _len = stylesPerFile.length; _i < _len; _i++) {
    array = stylesPerFile[_i];
    styles = styles.concat(array);
  }
  stylesMap = {};
  for (_j = 0, _len1 = styles.length; _j < _len1; _j++) {
    style = styles[_j];
    stylesMap[style.name] = style.propertyObjectsArray;
  }
  return stylesMap;
};

exports.getRealStyle = function(styleClass, realStyles) {
  styleClass = '.' + styleClass;
  if (realStyles[styleClass] != null) {
    return realStyles[styleClass];
  } else {
    return void 0;
  }
};

serializeStyle = function(style) {
  var styleString;
  styleString = style.property + ':' + style.value + ';';
  return styleString;
};

exports.serializeStylesArray = function(stylesArray) {
  var style, stylesString, _i, _len;
  stylesString = '';
  for (_i = 0, _len = stylesArray.length; _i < _len; _i++) {
    style = stylesArray[_i];
    stylesString = stylesString + serializeStyle(style);
  }
  return stylesString;
};
