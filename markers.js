// Generated by CoffeeScript 1.6.3
var markers, util, verbex;

util = require('./util');

verbex = require('verbal-expressions');

exports.anything = verbex().then('...').maybe('.').maybe('.').anything();

markers = {};

markers.array = [];

exports.markers = markers;

exports.load = function(callback) {
  var csvConverter, csvFile, csvToJsonConverter;
  util.timelog('Loading markers');
  csvToJsonConverter = require('csvtojson').core.Converter;
  csvConverter = new csvToJsonConverter();
  csvConverter.on("end_parsed", function(jsonFromCss) {
    markers.array = jsonFromCss.csvRows;
    util.timelog('Sorting markers');
    markers.array.sort(function(a, b) {
      if (a.WordOrPattern > b.WordOrPattern) {
        return 1;
      } else {
        return -1;
      }
    });
    util.timelog('Sorting markers');
    util.timelog('Loading markers');
    return callback();
  });
  csvFile = './markers.csv';
  return csvConverter.from(csvFile);
};