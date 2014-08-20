#
# Purges the local data files repository.
# Note: since the repository may be created with some special settings for performace optimization,
#       we don't delete the directory itself, only its content (for now)
#

exec        = require '../util/execOsCommand'
wait        = 2

purge = () -> 

  exec("""rm #{docsDataDir}/* -r""", (error) -> 
    if error
      console.error 'purging the local data-files repository failed'
      throw error
  )

waitAndGo = (docsDataDir) ->

  console.log ""
  console.log """ATTENTION!!! if not interupted, the local data-files repository (#{docsDataDir}) will be purged in #{wait} seconds"""
  console.log ""
  setTimeout(purge, wait * 1000)

#
# Check the folder. If appropriate initiate its purge.
#

docsDataDir = require('../data/dataWriter').docsDataDir

if docsDataDir.length < 3 # just a precaution...
  console.error 'Internal Error: local data-files directory must be over 2 characters in length. Purge aborted.'
  return 

exec("""ls #{docsDataDir}""", (error, stdout, stderr) -> 
  if error
    throw error

  if stdout.length is 0
    console.log 'local data-files repository does not yet exist, nothing to do'
    return

  waitAndGo(docsDataDir)  
)

