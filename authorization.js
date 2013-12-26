// Generated by CoffeeScript 1.6.3
exports.googleAuthSetup = function(app, host, routes) {
  var GoogleStrategy, passport;
  passport = require('passport');
  GoogleStrategy = require('passport-google').Strategy;
  passport.use(new GoogleStrategy({
    returnURL: 'http://' + host + '/auth/google/return',
    realm: 'http://' + host + '/auth/google'
  }, function(identifier, profile, done) {
    return console.log('authorized user ' + identifier + '\n' + JSON.stringify(profile));
  }));
  app.get('/auth/google', passport.authenticate('google'));
  app.get('/auth/google/return', routes.index);
  return true;
};
