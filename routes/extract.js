// Generated by CoffeeScript 1.4.0
var css, filterImages, filterZeroLengthText, html, isImage, model, output, soup, timer, util;

require("fs");

util = require("../util");

timer = require("../timer");

css = require("../css");

html = require("../html");

model = require("../model");

soup = require("../soup");

output = require("../output");

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
  var augmentEachDiv, div, divTokens, divs, divsWithStyles, endsSpaceDelimited, name, outputHtml, path, plainText, rawHtml, rawRelevantDivs, realStyles, token, tokens, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _len6, _len7, _m, _n, _o, _p;
  timer.start('Extraction from html stage A');
  path = '../local-copies/' + 'html-converted/';
  name = req.query.name;
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString();
  realStyles = css.simpleFetchStyles(rawHtml, path + name + '/');
  rawRelevantDivs = html.removeOuterDivs(rawHtml);
  divsWithStyles = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = rawRelevantDivs.length; _i < _len; _i++) {
      div = rawRelevantDivs[_i];
      _results.push(html.representDiv(div));
    }
    return _results;
  })();
  divsWithStyles = filterImages(divsWithStyles);
  for (_i = 0, _len = divsWithStyles.length; _i < _len; _i++) {
    div = divsWithStyles[_i];
    html.stripSpanWrappers(div);
  }
  divsWithStyles = filterZeroLengthText(divsWithStyles);
  divs = divsWithStyles.length;
  endsSpaceDelimited = 0;
  for (_j = 0, _len1 = divsWithStyles.length; _j < _len1; _j++) {
    div = divsWithStyles[_j];
    if (util.isAnySpaceChar(util.lastChar(div.text))) {
      endsSpaceDelimited += 1;
    }
  }
  console.log(endsSpaceDelimited);
  console.log(endsSpaceDelimited / divs);
  if ((endsSpaceDelimited / divs) < 0.3) {
    augmentEachDiv = true;
  } else {
    augmentEachDiv = false;
  }
  divTokens = [];
  for (_k = 0, _len2 = divsWithStyles.length; _k < _len2; _k++) {
    div = divsWithStyles[_k];
    tokens = html.tokenize(div.text);
    for (_l = 0, _len3 = tokens.length; _l < _len3; _l++) {
      token = tokens[_l];
      switch (token.metaType) {
        case 'regular':
          token.styles = div.styles;
      }
    }
    if (augmentEachDiv) {
      tokens.push({
        'metaType': 'delimiter'
      });
    }
    divTokens.push(tokens);
  }
  tokens = [];
  for (_m = 0, _len4 = divTokens.length; _m < _len4; _m++) {
    div = divTokens[_m];
    for (_n = 0, _len5 = div.length; _n < _len5; _n++) {
      token = div[_n];
      tokens.push(token);
    }
  }
  for (_o = 0, _len6 = tokens.length; _o < _len6; _o++) {
    token = tokens[_o];
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
  tokens.reduce(function(x, y, index) {
    if (x.metaType === 'regular' && y.metaType === 'regular') {
      if (util.endsWith(x.text, '-')) {
        x.text = x.text.slice(0, -1);
        x.text = x.text.concat(y.text);
        tokens.splice(index, 1);
        return x;
      }
    }
    return y;
  });
  plainText = '';
  for (_p = 0, _len7 = tokens.length; _p < _len7; _p++) {
    token = tokens[_p];
    if (token.metaType === 'regular') {
      plainText = plainText.concat(token.text);
    } else {
      plainText = plainText.concat(' ');
    }
  }
  timer.end('Extraction from html stage A');
  outputHtml = soup.build(plainText);
  return output.serveOutput(outputHtml, name, res);
};
