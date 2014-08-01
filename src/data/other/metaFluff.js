// Generated by CoffeeScript 1.6.3
var add, es, fluff, util;

util = require('./util');

es = require('./elasticsearch');

add = function(string, type, article, tagger) {
  return esClient.create({
    index: 'fluff',
    type: type,
    body: {
      text: text,
      article: article,
      tagger: tagger
    }
  }, function(error) {
    if (error != null) {
      return console.error(error);
    }
  });
};

fluff = {};

exports.fluff = fluff;

exports.load = function() {
  util.timelog('Loading fluff database');
  return util.timelog('Loading fluff database');
};