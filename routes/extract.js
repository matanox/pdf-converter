require('fs')

exports.go = function(req, res){
  rawHtml = fs.readFileSync('../local-copies/' + 'html-converted/' + req.query.file).toString()
  console.log(rawHtml)
  res.send('read raw html of length ' + rawHtml.length + ' bytes')
}