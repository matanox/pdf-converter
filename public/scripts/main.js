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

