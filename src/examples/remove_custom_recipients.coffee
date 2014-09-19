_     = require 'underscore'
async = require 'async'
cred  = require '../config/private_credentials'
util  = require 'util'
{API}   = require 'coffee_salsa'

api = new API cred
api.authenticate (err, results) ->
  throw err if err?
  console.log results 

  # Retrieve a list of recipient keys.  Errors are noisily fatal.
  #
  qs = 
    object: 'recipient'
    json: true
    limit:
      offset: 0
  api.getObjects qs, (err, records) ->
    throw err if err?
    process.exit 0 unless records?.length > 0

    keys = (record.recipient_KEY for record in records)
    console.log "Found", keys.length, "keys"
    process.exit 0 unless keys.length > 0

    # Delete the provided key from recipient.
    deleter = (key, cb) ->
      console.log "Deleting recipient:#{key}"
      qs = 
        object: 'recipient'
        key: key
      api.deleteObject qs, (err, results) ->
        console.log "Deleting recipient:#{key} returned err #{err}, results #{results}"
        cb err, results

    async.mapSeries keys, deleter, (err, results) ->
      throw err if err?
      results = _.flatten results
      console.log "Deleted", results.length, "recipient records"
      process.exit 0
