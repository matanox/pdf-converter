// Generated by CoffeeScript 1.6.3
var css, ctype, filterImages, filterZeroLengthText, html, isImage, markers, model, output, timer, util, verbex;

require("fs");

util = require("../util");

timer = require("../timer");

css = require("../css");

html = require("../html");

model = require("../model");

output = require("../output");

ctype = require("../ctype");

markers = require("../markers");

verbex = require('verbal-expressions');

isImage = function(text) {
  return util.startsWith(text, "<img ");
};

filterImages = function(ourDivRepresentation) {
  var div, filtered, _i, _len;
  filtered = [];
  for (_i = 0, _len = ourDivRepresentation.length; _i < _len; _i++) {
    div = ourDivRepresentation[_i];
    if (!isImage(div.text)) {
      filtered.push(div);
    }
  }
  return filtered;
};

filterZeroLengthText = function(ourDivRepresentation) {
  var div, filtered, _i, _len;
  filtered = [];
  for (_i = 0, _len = ourDivRepresentation.length; _i < _len; _i++) {
    div = ourDivRepresentation[_i];
    if (!(div.text.length === 0)) {
      filtered.push(div);
    }
  }
  return filtered;
};

exports.go = function(req, res) {
  var abbreviations, connect_token_group, cssClass, cssClasses, docSieve, documentQuantifiers, dom, group, groups, handler, htmlparser, id, inputStylesMap, iterator, lastRowPosLeft, markSentence, name, node, nodesWithStyles, parser, path, rawHtml, style, styles, textIndex, token, tokenArray, tokenArrays, tokens, _i, _j, _k, _l, _len, _len1, _len10, _len2, _len3, _len4, _len5, _len6, _len7, _len8, _len9, _m, _n, _o, _p, _q, _r, _ref, _s;
  util.timelog('Extraction from html stage A');
  path = '../local-copies/' + 'html-converted/';
  name = req.query.name;
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString();
  inputStylesMap = css.simpleFetchStyles(rawHtml, path + name + '/');
  htmlparser = require("htmlparser2");
  util.timelog('htmlparser2');
  handler = new htmlparser.DomHandler(function(error, dom) {
    if (error) {
      return console.log('htmlparser2 failed loading document');
    } else {
      return console.log('htmlparser2 loaded document');
    }
  });
  parser = new htmlparser.Parser(handler);
  parser.parseComplete(rawHtml);
  dom = handler.dom;
  util.timelog('htmlparser2');
  nodesWithStyles = html.representNodes(dom);
  tokenArrays = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = nodesWithStyles.length; _i < _len; _i++) {
      node = nodesWithStyles[_i];
      _results.push(html.tokenize(node));
    }
    return _results;
  })();
  tokens = [];
  for (_i = 0, _len = tokenArrays.length; _i < _len; _i++) {
    tokenArray = tokenArrays[_i];
    for (_j = 0, _len1 = tokenArray.length; _j < _len1; _j++) {
      token = tokenArray[_j];
      tokens.push(token);
    }
  }
  tokens.reduce(function(x, y) {
    if (y.metaType === 'delimiter') {
      y.stylesArray = x.stylesArray;
    }
    return y;
  });
  for (_k = 0, _len2 = tokens.length; _k < _len2; _k++) {
    token = tokens[_k];
    if (token.metaType === 'regular') {
      if (token.text.length === 0) {
        throw "Error - zero length text in data";
      }
    }
  }
  if (tokens.length === 0) {
    console.log("No text was extracted from input");
    throw "No text was extracted from input";
  }
  for (_l = 0, _len3 = tokens.length; _l < _len3; _l++) {
    token = tokens[_l];
    token.finalStyles = {};
    token.positionInfo = {};
    _ref = token.stylesArray;
    for (_m = 0, _len4 = _ref.length; _m < _len4; _m++) {
      cssClasses = _ref[_m];
      for (_n = 0, _len5 = cssClasses.length; _n < _len5; _n++) {
        cssClass = cssClasses[_n];
        styles = css.getFinalStyles(cssClass, inputStylesMap);
        if (styles != null) {
          for (_o = 0, _len6 = styles.length; _o < _len6; _o++) {
            style = styles[_o];
            if (util.isAnyOf(style.property, css.positionData)) {
              token.positionInfo[style.property] = style.value;
            } else {
              token.finalStyles[style.property] = style.value;
            }
          }
        }
      }
    }
    if (util.objectPropertiesCount(token.finalStyles) === 0) {
      console.warn('No final styles applied to token');
      console.dir(token);
    }
  }
  util.first(tokens).lineLocation = 'opener';
  lastRowPosLeft = null;
  tokens.reduce(function(a, b) {
    if (parseInt(b.positionInfo.bottom) < parseInt(a.positionInfo.bottom)) {
      a.lineLocation = 'closer';
      b.lineLocation = 'opener';
      if (lastRowPosLeft != null) {
        if (parseInt(b.positionInfo.left) > parseInt(lastRowPosLeft)) {
          a.paragraph = 'closer';
          b.paragraph = 'opener';
        }
      }
      lastRowPosLeft = b.positionInfo.left;
    }
    return b;
  });
  util.last(tokens).lineLocation = 'closer';
  iterator = function(tokens, iterationFunc) {
    var a, b, i, _results;
    i = 1;
    _results = [];
    while (i < tokens.length) {
      a = tokens[i - 1];
      b = tokens[i];
      _results.push(i = i + iterationFunc(a, b, i, tokens));
    }
    return _results;
  };
  console.log(tokens.length);
  iterator(tokens, function(a, b, i, tokens) {
    var newDelimiter;
    if (b.lineLocation === 'opener') {
      if (a.lineLocation === 'closer') {
        if (a.metaType === 'regular') {
          if (util.endsWith(a.text, '-')) {
            a.text = a.text.slice(0, -1);
            a.text = a.text.concat(b.text);
            tokens.splice(i, 1);
            return 0;
          } else {
            newDelimiter = {
              'metaType': 'delimiter'
            };
            newDelimiter.styles = a.styles;
            newDelimiter.finalStyles = a.finalStyles;
            tokens.splice(i, 0, newDelimiter);
            return 2;
          }
        }
      }
    }
    return 1;
  });
  tokens.reduce(function(a, b, index) {
    if (a.metaType === 'regular' && b.metaType === 'regular') {
      if (util.endsWith(a.text, '-')) {
        a.text = a.text.slice(0, -1);
        a.text = a.text.concat(b.text);
        tokens.splice(index, 1);
        return a;
      }
    }
    return b;
  });
  util.timelog('Extraction from html stage A');
  util.timelog('ID seeding');
  id = 0;
  for (_p = 0, _len7 = tokens.length; _p < _len7; _p++) {
    token = tokens[_p];
    token.id = id;
    id += 1;
  }
  util.timelog('ID seeding');
  textIndex = [];
  for (_q = 0, _len8 = tokens.length; _q < _len8; _q++) {
    token = tokens[_q];
    if (token.metaType === 'regular') {
      textIndex.push({
        text: token.text,
        id: token.id
      });
    }
  }
  util.timelog('Index creation');
  textIndex.sort(function(a, b) {
    if (a.text > b.text) {
      return 1;
    } else {
      return -1;
    }
  });
  util.timelog('Index creation');
  /*
  markersRegex = ''
  
  for m in [0..markers.markers.array.length-1]
    markerText = markers.markers.array[m].WordOrPattern
    markerRegex = ''
  
    unless m is 40 then markersRegex += "|"  # add logical 'or' to regex 
  
    if markers.anything.test(markerText)
      console.log('in split for: ' + markerText)
      splitText = markerText.split(markers.anything)
      for s in [0..splitText.length-1]
        unless s is 0 then markerRegex += '|'    # add logical 'or' to regex 
        if markers.anything.test(splitText[s])
          markerRegex += '\s'                    # add logical 'and then anything' to regex
          console.log('anything found')
        else
          markerRegex += splitText[s]            # add as-is text to the regex
          console.log('no anything marker')
    else
      markerRegex += markerText
  
  
    markersRegex += markerRegex
    #console.log(markerText)
    #console.log(markerRegex.source)
    console.log(markersRegex)
  
    
    util.timelog('Markers visualization') 
    #console.log('Marker regex length is ' + markersRegex.toString().length)
    #console.log(markersRegex.source)
    #testverbex = verbex().then("verbex testing sentence").or().then("and more")
    #console.log(testverbex.toRegExp().source)
  */

  docSieve = markers.createDocumentSieve(markers.baseSieve);
  for (_r = 0, _len9 = tokens.length; _r < _len9; _r++) {
    token = tokens[_r];
    if (token.metaType === 'regular') {
      token.calculatedProperties = [];
      if (util.pushIfTrue(token.calculatedProperties, ctype.testPureUpperCase(token.text))) {
        console.log('All Caps Style detected for word: ' + token.text);
      }
      if (util.pushIfTrue(token.calculatedProperties, ctype.testInterspacedTitleWord(token.text))) {
        console.log('Interspaced Title Word detected for word: ' + token.text);
      }
    }
  }
  util.timelog('Sentence tokenizing');
  connect_token_group = function(_arg) {
    var group, token;
    group = _arg.group, token = _arg.token;
    group.push(token);
    return token.partOf = group;
  };
  abbreviations = 0;
  groups = [];
  group = [];
  for (_s = 0, _len10 = tokens.length; _s < _len10; _s++) {
    token = tokens[_s];
    if (token.type = 'regular') {
      connect_token_group({
        group: group,
        token: token
      });
      if (token.text === '.') {
        if (!(group.length > (1 + 1))) {
          abbreviations += 1;
        } else {
          groups.push(group);
          group = [];
        }
      }
    }
  }
  if (group.length !== 0) {
    groups.push(group);
  }
  util.timelog('Sentence tokenizing');
  documentQuantifiers = {};
  documentQuantifiers['sentences'] = groups.length;
  documentQuantifiers['period-trailed-abbreviations'] = abbreviations;
  console.dir(documentQuantifiers);
  util.timelog('Markers visualization');
  markSentence = function(sentenceIdx) {
    var marker, matchedMarkers, outputHtml, sentence, _len11, _len12, _t, _u;
    sentence = groups[sentenceIdx];
    matchedMarkers = [];
    for (_t = 0, _len11 = sentence.length; _t < _len11; _t++) {
      token = sentence[_t];
      if (token.metaType !== 'delimiter') {
        for (_u = 0, _len12 = docSieve.length; _u < _len12; _u++) {
          marker = docSieve[_u];
          switch (marker.markerTokens[marker.nextExpected].metaType) {
            case 'regular':
              if (token.text === marker.markerTokens[marker.nextExpected].text) {
                if (marker.nextExpected === (marker.markerTokens.length - 1)) {
                  matchedMarkers.push(marker);
                  token.finalStyles['color'] = 'red';
                  marker.nextExpected = 0;
                } else {
                  marker.nextExpected += 1;
                }
              } else {
                if (marker.markerTokens[marker.nextExpected].metaType !== 'anyOneOrMore') {
                  marker.nextExpected = 0;
                }
              }
              break;
            case 'anyOneOrMore':
              if (marker.nextExpected === (marker.markerTokens.length - 1)) {
                marker.nextExpected = 0;
              } else {
                if (token.text === marker.markerTokens[marker.nextExpected + 1].text) {
                  if ((marker.nextExpected + 1) === (marker.markerTokens.length - 1)) {
                    matchedMarkers.push(marker);
                    token.finalStyles['color'] = 'red';
                    marker.nextExpected = 0;
                  } else {
                    marker.nextExpected += 2;
                  }
                }
              }
          }
        }
      }
    }
    sentenceIdx += 1;
    if (sentenceIdx < groups.length) {
      return setImmediate(function() {
        return markSentence(sentenceIdx + 1);
      });
    } else {
      util.timelog('Markers visualization');
      outputHtml = html.buildOutputHtml(tokens, inputStylesMap);
      return output.serveOutput(outputHtml, name, res);
    }
  };
  return markSentence(0);
};