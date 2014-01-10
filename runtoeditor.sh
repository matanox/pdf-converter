gedit run.out &
#authbind --deep coffee app.coffee > run.out
authbind --deep nodemon --ext '.coffee|.js|.html|.css' app.coffee > run.out
