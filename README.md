# About

This project has been forked, for the sake of running only core parts of the initial POC back-end which seem to work well with javascript or node.js. Namely:

+ activating pdf2htmlEX
+ creating a collection of tokens derived from the html and css created by pdf2htmlEX. Rational here is that it has some sense parsing html and css with javascript, and that the javascript libraries already used for that, will not have equivalent library implementations in Scala, thus it's nice to pass on not re-implementing that html/css processing part

The idea is that this code will be invoked by Scala, along with some context, and return a collection of tokens that is the most primitive conversion of the original pdf into consequitive tokens. All fancy algorithm should be left for the more suitable Scala language.

# Technical comments from the original project that mostly still hold follow.

This is an [express](http://expressjs.com/faq.html) app. Express.js documentation is not stellar, 
but it is simple enough to follow and the main advantage of choosing it is its leanness (and widespread adoption).
This app uses coffeescript. Using sublime, every coffeescript source file (`.coffee`) automatially gets compiled 
to a same-named javascript (`.js`) file. 

To run the app in development, with auto-restart upon source code change: `./start.sh`

To run all its [mocha](http://mochajs.org/) tests (served from `/tests`): `./test.sh`

To install: clone this repo and `./install.sh` (and install mocha for testing, if not already installed)

## Guidelines
+ Each significant step is built as its own http directive, so that it can be invoked on its own during development.
+ The minimum required javascript level is now ES5, and should preserve.
+ For asynchronous testing, it is suggested to use [vows.js](http://vowsjs.org/) and mocha for the rest. [sinon.js](http://sinonjs.org/docs/) may be used for time related testing or mocks and stubs, if applicable.
