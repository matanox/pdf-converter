// Generated by CoffeeScript 1.4.0
var util;

require("fs");

util = require("../myStringUtil");

exports.go = function(req, res) {
  var div, divs, divsContent, name, path, rawHtml;
  path = '../local-copies/' + 'html-converted/';
  name = req.query.name;
  rawHtml = fs.readFileSync(path + name + '/' + name + ".html").toString();
  divs = util.removeOuterDivs(rawHtml);
  divsContent = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = divs.length; _i < _len; _i++) {
      div = divs[_i];
      _results.push(util.simpleGetDivContent(div));
    }
    return _results;
  })();
  res.write("read raw html of length " + rawHtml.length + " bytes");
  util.simpleGetStyles(rawHtml, path + name + '/');
  return res.end;
};
