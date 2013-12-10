//
// Module dependencies and general initalization
//

requirejs.config({
    enforceDefine: false,
    paths: {
        filePicker: 'https://api.filepicker.io/v1/filepicker',
		jquery: 'https://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min',
	}
   });

require(['filePicker'], function() {
    console.log('connecting to filepicker');
    filepicker.setKey('A98TZEfEaSi6e7ru2EZnxz');   
});

// TODO: move this under the auspices of require if it gets buggy
// TODO: (possibly) get rid of jquery
require(['jquery'], function() {
	$.getScript("./hadasino/socket.io.js").done(function( data, textStatus, jqxhr ) {
  		/* console.log( data ); // Data returned
  		console.log( textStatus ); // Success
  		console.log( jqxhr.status ); // 200 */
		console.log("hadasino loaded")

		// connect to Hadas server and listen for reload events
		// need to make sure this runs after at least socket.io was loaded.
		//
		var socket = io.connect('http://localhost:1338');		
		socket.emit('projectClient');		
		socket.on('clientRecycle', function() {
			console.log("trying to reload")
			location.reload(true);
		});
	}).fail(function(jqxhr, settings, exception) {
		console.log("failed loading hadasino:");
		console.log( jqxhr.status ); 
		console.log( settings ); 
		console.log( exception ); 
	});
});

