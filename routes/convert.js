/*
 * Handles the conversion from pdf to html, and forwards to next stage.
 */

getFromUrl = require("request")
exec = require('child_process').exec
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
	}).pipe(fs.createWriteStream(outFile))
}

exports.go = function(req, res){

	function redirectToRawHTML(redirectString)
	{
		
		console.log("Passing html result to next level handler, by redirecting to: " + redirectString)

		res.writeHead(301, {'Location': redirectString})
    	res.end();
	}

	function processFile(redirectString)
	{
		
		console.log("Passing html result to next level handler, by redirecting to: " + redirectString)

		res.writeHead(301, {'Location': redirectString})
    	res.end();
	}

	function convert(localCopy)
	{
		/* 
		 * html2pdfEX doesn't have an option to pipe the output, so passing its output around
		 * is just a bit clumsier than it could have been. We use a directory structure one level up
		 * of this project, to store originals and conversion artifacts, as a way to share them with
		 * another web server running on the same server.
		 *
		 * For the output of html2pdfEX for a given input PDF document, we create a folder using its 
		 * randomly generated file name generated by html2pdfEX, and in it we store all the conversion 
		 * outputs for that file - the html, and accompanying files such as css, fonts, images, 
		 * and javascript that the html2pdfEX output needs to have. 
		 */

		console.log('Starting the conversion from pdf to html')

		//res.send('Please wait...'');

		execCommand = executable + ' '
		name = localCopy.replace('../local-copies/pdf/', '').replace('.pdf', '') // extract the file name
		outFileName = name + '.html'
		outFolder = '../local-copies/' + 'html-converted/'
		execCommand += localCopy + ' ' + executalbeParams + ' ' + '--dest-dir=' + outFolder + "/" + name
		console.log(execCommand)

	  	exec(execCommand, function (error, stdout, stderr) {
	    	console.log(executable + '\'s stdout: ' + stdout)
	    	console.log(executable + '\'s stderr: ' + stderr)
	    	if (error !== null) {
	      		console.log(executable + '\'sexec error: ' + error)
		    }
		    else {
			  // KEEP THIS FOR LATER: redirectToRawHTML('http://localhost:8080/' + 'serve-original-as-html/' + name + "/" + outFileName)
			  processFile('http://localhost:8080/' + 'process-file/' + name + "/" + outFileName)
		    }
		});
	}

	fetch(req.query.tempLocation, convert); // fetch the upload and pass control to the convert function
};
