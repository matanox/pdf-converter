# Assumes npm install -g nodemon
#
# NOTE: for verbose nodemon output run this instead: authbind --deep nodemon -V --ext coffee,js,html,css app.coffee
# NOTE: ignore list is defined in .nodemonignore
#
authbind --deep nodemon --watch src --ext coffee,js,html,css src/app.coffee
