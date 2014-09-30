{API}   = require '../lib/api'
mules   = require '../credentials/mules'
util    = require 'util'

api = new API mules
api.authenticate (err, results) ->
    throw err if err?
    console.log results 

    qs = 
        object: 'supporter'
        json: true
        limit:
            offset: -1
            count: 1e7
    api.getObjects qs, (err, records) ->
        throw err if err?
        console.log "count:", records.length
        console.log i, records[i].Email for i in [0...records.length]
        process.exit 0
