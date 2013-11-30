getFromUrl = require("request")
exec = require('child_process').exec;
fs = require('fs')
require('stream')
executable = 'pdf2htmlEX'
executalbeParams = '--embed-css=0 --embed-font=0 --embed-image=0 --embed-javascript=0'

/*
 * Fetches the upload from Ink File Picker (writing it into local file).
 * If it works - invoke the passed along callback function.
 */
function fetch(inkUrl, callOnSuccess)
{
	//outFile = inkUrl + '.pdf';
	outFile = '../local-copies/' + 'pdf/' + inkUrl.replace("https://www.filepicker.io/api/file/","") + '.pdf'
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
			
		console.log('Starting the conversion from pdf to html')

		//res.send('Please wait...'');

		execCommand = executable + ' '
		name = localCopy.replace('../local-copies/pdf/', '').replace('.pdf', '')
		outFileName = name + '.html'
		outFolder = '../local-copies/' + 'html-converted/'
		execCommand += localCopy + ' ' + executalbeParams + ' ' + '--dest-dir=' + outFolder + "/" + name
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
				 * Needs some readability cleanup, if this code survives.
				 */
				redirectString = 'http://localhost:8080/' + 'serve-original-as-html/' + name + "/" + outFileName
				console.log("Redirecting to: " + redirectString)

    			res.writeHead(301, {'Location': redirectString});
		    	res.end();
		    }
		});
	}

	fetch(req.query.tempLocation, convert); // fetch the upload and pass control to the convert function
};
