# Code comments

This is an [express](http://expressjs.com/faq.html) app. Express.js documentation is not stellar, 
but it is simple enough to follow and the main advantage of choosing it is its leanness (and widespread adoption).
This app uses coffeescript. Using sublime, every coffeescript source file (`.coffee`) automatially gets compiled 
to a same-named javascript (`.js`) file. 

To run the app in development, with auto-restart upon source code change: `./start.sh`

To run all its [mocha](http://visionmedia.github.io/mocha/) tests (served from `/tests`): `./test.sh`

To install: clone this repo and `./install.sh` (and install mocha for testing, if not already installed)

## Guidelines
+ Each significant step is built as its own http directive, so that it can be invoked on its own during development.
+ The minimum required javascript level is now ES5, and should preserve.
+ For asynchronous testing, it is suggested to use [vows.js](http://vowsjs.org/) and mocha for the rest. [sinon.js](http://sinonjs.org/docs/) may be used for time related testing or mocks and stubs, if applicable.

## License
There is no license permitting reuse of this code for now. 
