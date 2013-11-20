getFromUrl = require("request")
exec = require('child_process').exec;
fs = require('fs')
require('stream')
executable = 'pdf2htmlEX'
execCommand = executable + ' '

/*
 * Fetches the upload from Ink File Picker (writing it into local file).
 * If it works - invoke the passed along callback function.
 */
function fetch(inkUrl, callOnSuccess)
{
	//outFile = inkUrl + '.pdf';
	outFile = 'local-copies/' + 'pdf/' + inkUrl.replace("https://www.filepicker.io/api/file/","") + '.pdf'
	download = getFromUrl(inkUrl, function(error, response, body){
		if (!error && response.statusCode == 200) 
			callOnSuccess(outFile);
		else
		{
			console.log('fetching from InkFilepicker returned http status ' + response.statusCode);
			if (error)
			{
				console.log('fetching from InkFilepicker returned error ' + error);			
			}
		}		
	}).pipe(fs.createWriteStream(outFile));	
}

exports.go = function(req, res){

	function convert(localCopy)
	{
			
		//res.send('Please wait...'');	

		execCommand += localCopy += ' ' + '--dest-dir=' + 'local-copies/' + 'html-converted/'
		console.log(execCommand)

	  	exec(execCommand, function (error, stdout, stderr) {
	    	console.log(executable + '\'s stdout: ' + stdout);
	    	console.log(executable + '\'s stderr: ' + stderr);
	    	if (error !== null) {
	      		console.log(executable + '\'sexec error: ' + error);
		    }
		    else {
		    	console.log('Passing html result to next level handler')
/* 
				 * this long concatentaion is the redirect to the back-end server, 
				 * with the relative location of the output file. Needs some 
				 * readability cleanup, if this code survives.
				 *
				 */
				redirectString = 'http://localhost:8080/' + '?' 
				+ '../front-end/' + 'local-copies/' + 'html-converted/' + 
				localCopy.replace('local-copies/pdf/', '').replace('.pdf', '') + '.html'
				    	
    			res.writeHead(301, {'Location': redirectString});
		    	res.end();
		    }
		});
	}

	fetch(req.query.tempLocation, convert); // fetch the upload and pass control to the convert function
};
