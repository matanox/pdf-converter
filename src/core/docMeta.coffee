#
# Get meta-data cotained in the pdf file, as much as any is contained
#

storeCmdOutput = require '../util/storeCmdOutput'
exports.storePdfMetaData = (name, localCopy, docLogger) ->
  params =  
    execCommand : 'pdfinfo -meta', 
    writerType  : 'pdfMeta',
    description : 'Getting pdf file metadata using pdfinfo'

  storeCmdOutput(name, localCopy, docLogger, params)

exports.storePdfFontsSummary = (name, localCopy, docLogger) ->

  params =  
    execCommand : 'pdffonts', 
    writerType  : 'pdfFonts',
    description : 'Getting pdf fonts summary using pdffonts (1 of 2)'

  storeCmdOutput(name, localCopy, docLogger, params)

  params =  
    execCommand : 'pdffonts -subst', 
    writerType  : 'pdfFonts',
    description : 'Getting pdf fonts summary using pdffonts (2 of 2)'

  storeCmdOutput(name, localCopy, docLogger, params)
  