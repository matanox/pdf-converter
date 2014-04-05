util    = require '../util'
logging = require '../logging' 
docMeta = require '../docMeta'
storage = require '../storage'
require 'stream'
exec   = require("child_process").exec
riak   = require('riak-js').getClient({host: "localhost", port: "8098"})
fs     = require 'fs'
crypto = require 'crypto'

executable = "pdf2htmlEX"
executalbeParams = "--embed-css=0 --embed-font=0 --embed-image=0 --embed-javascript=0"

#
# * Handles the conversion from pdf to html, and forwards to next stage.
# 
exports.go = (localCopy, docLogger, req, res) ->

  name = localCopy.replace("../local-copies/pdf/", "").replace(".pdf", "") # extract the file name
  req.session.name = name 

  hasher = crypto.createHash('md5')
  fileContent = fs.readFileSync(localCopy)

  util.timelog "hashing input file"
  hasher.update(fileContent)
  hash = hasher.digest('hex')
  util.timelog "hashing input file"
  console.log hash


  #
  # convert from pdf, unless conversion has been cached
  #
  # a hash of the input file content is saved here 
  # to a clustered storage database, to mark whether the file 
  # has already been converted with pdf2htmlEX.
  #
  # NOTE: if the actual local copy of the converstion outputs (at local-copies/html-converted/)
  #       has been cleared, an exception will be ultimately raised
  #
  riak.get('html', hash, (error, formerName) ->  # test for cached version

      if error?
        #
        # not cached - perform the conversion and then pass to extraction
        #
        util.timelog "from upload to serving"

        docMeta.storePdfMetaData localCopy, docLogger
        storage.store "pdf", name, fileContent, docLogger

        util.timelog "Conversion to html"
        docLogger.info "Starting the conversion from pdf to html"

        #docMeta.storePdfMetaData(name, localCopy)
        
        # 
        #	html2pdfEX doesn't have an option to pipe the output, so passing its output around
        #	is just a bit clumsier than it could have been. We use a directory structure one level up
        #	of this project, to store originals and conversion artifacts, as a way to share them with
        #	another web server running on the same server.
        #	
        #	For the output of html2pdfEX for a given input PDF document, we create a folder using its 
        #	randomly generated file name generated by html2pdfEX, and in it we store all the conversion 
        #	outputs for that file - the html, and accompanying files such as css, fonts, images, 
        #	and javascript that the html2pdfEX output comprises. 
        #		 
        
        #res.send('Please wait...'');
        execCommand = executable + " "
        
        outFolder = "../local-copies/" + "html-converted/"
        execCommand += localCopy + " " + executalbeParams + " " + "--dest-dir=" + outFolder + "/" + name
        docLogger.info execCommand
        exec execCommand, (error, stdout, stderr) ->
          docLogger.info executable + "'s stdout: " + stdout
          docLogger.info executable + "'s stderr: " + stderr
          if error isnt null
            docLogger.error executable + "'sexec error: " + error
          else
            
            # KEEP THIS FOR LATER: redirectToShowHtml('http://localhost:8080/' + 'serve-original-as-html/' + name + "/" + outFileName)
            # redirectToShowRaw('http://localhost/' + 'extract' +'?file=' + name + "/" + outFileName)
            util.timelog "Conversion to html", docLogger

            riak.save('html', hash, name, (error) -> 
              util.timelog "storing file hash to clustered storage", docLogger
              if error?
                docLogger.error("failed storing file hash to clustered storage"))

            require('./extract').go(req, name, res, docLogger)
            #redirectToExtract "http://localhost/" + "extract" + "?" + "name=" + name + "&" + "docLogger=" + docLogger

      #
      # cached - pass on to extraction as conversion has already taken place
      #
      else
        console.log('input file has already passed pdf2htmlEX conversion - skipping conversion')
        require('./extract').go(req, formerName, res, docLogger, output.serveViewerTemplate)
    )
  
  
redirectToShowHtml = (redirectString) ->
  docLogger.info "Passing html result to next level handler, by redirecting to: " + redirectString
  res.writeHead 301,
    Location: redirectString
  res.end()

redirectToExtract = (redirectString) ->
  docLogger.info "Passing html result to next level handler, by redirecting to: " + redirectString
  res.writeHead 301,
    Location: redirectString
  res.end()
