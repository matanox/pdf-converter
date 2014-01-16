// Generated by CoffeeScript 1.6.3
var tty;

tty = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m',
  magenta: '\x1b[35m',
  endColor: '\x1b[0m'
};

exports.logGreen = function(text) {
  return console.log(tty.green + text + tty.endColor);
};

exports.logYellow = function(text) {
  return console.log(tty.yellow + text + tty.endColor);
};

exports.logRed = function(text) {
  return console.log(tty.red + text + tty.endColor);
};

exports.logBlue = function(text) {
  return console.log(tty.blue + text + tty.endColor);
};

exports.logPerf = function(text) {
  return console.log(tty.magenta + text + tty.endColor);
};
