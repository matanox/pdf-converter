getFromUrl = require("request")
exec = require('child_process').exec;
fs = require('fs')
require('stream')
executable = 'pdf2htmlEX'
execCommand = executable + ' '

/*
 * Fetches the upload from Ink File Picker (writing it into local file).
 * If it works - invoke the passed along callback.
 */
function fetch(inkUrl, callback)
{
	//outFile = inkUrl + '.pdf';
	outFile = 'local-copies/' + 'pdf/' + inkUrl.replace("https://www.filepicker.io/api/file/","") + '.pdf'
	download = getFromUrl(inkUrl, function(error, response, body){
		if (!error && response.statusCode == 200) 
			callback(outFile);
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

		execCommand += localCopy += ' ' + '--dest-dir=' + 'local-copies/' + 'html-converted/'
		console.log(execCommand)

	  	exec(execCommand, function (error, stdout, stderr) {
	    	console.log(executable + '\'s stdout: ' + stdout);
	    	console.log(executable + '\'s stderr: ' + stderr);
	    	if (error !== null) {
	      		console.log(executable + '\'sexec error: ' + error);
		    }
		});
		res.send("Please wait...");	
	}

	fetch(req.query.tempLocation, convert);
};
