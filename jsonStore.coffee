# from https://github.com/alexkwolfe/node-store

async = require("async")
fs = require("fs")
path = require("path")
uuid = require("node-uuid")
mkdirp = require("mkdirp")
module.exports = (dir) ->
  dir = dir or path.join(process.cwd(), "store")
  
  # store in this directory
  dir: dir
  
  # list all stored objects by reading the file system
  list: (cb) ->
    self = this
    action = (err) ->
      return cb(err)  if err
      readdir dir, (err, files) ->
        return cb(err)  if err
        files = files.filter((f) ->
          f.substr(-5) is ".json"
        )
        fileLoaders = files.map((f) ->
          (cb) ->
            loadFile f, cb
        )
        async.parallel fileLoaders, (err, objs) ->
          return cb(err)  if err
          sort objs, cb



    mkdirp dir, action

  
  # store an object to file
  add: (obj, cb) ->
    action = (err) ->
      return cb(err)  if err
      json = undefined
      try
        json = JSON.stringify(obj, null, 2)
      catch e
        return cb(e)
      obj.id = obj.id or uuid.v4()
      fs.writeFile path.join(dir, obj.id + ".json"), json, "utf8", (err) ->
        return cb(err)  if err
        cb()


    mkdirp dir, action

  
  # delete an object's file
  remove: (obj, cb) ->
    action = (err) ->
      return cb(err)  if err
      fs.unlink path.join(dir, obj.id + ".json"), (err) ->
        cb err


    mkdirp dir, action

  
  # load an object from file
  load: (id, cb) ->
    mkdirp dir, (err) ->
      return cb(err)  if err
      loadFile path.join(dir, id + ".json"), cb


readdir = (dir, cb) ->
  fs.readdir dir, (err, files) ->
    return cb(err)  if err
    files = files.map((f) ->
      path.join dir, f
    )
    cb null, files


loadFile = (f, cb) ->
  fs.readFile f, "utf8", (err, code) ->
    return cb("error loading file" + err)  if err
    try
      cb null, JSON.parse(code)
    catch e
      cb "Error parsing " + f + ": " + e


sort = (objs, cb) ->
  async.sortBy objs, ((obj, cb) ->
    cb null, obj.name or ""
  ), cb
