cred        = require '../config/sample'
util		= require "util"
{API}       = require "../lib/api"

api         = new API cred

# Retrieve events tagged with `bangarang`.  Note that
# this just returns the first batch of events if there
# are more than 500.
#
api.authenticate (err, res, body) ->
    if err?
        console.log "Authentication error: #{err}"
        process.exit 1
    qs =
        json: true
        object: "tag"
    api.getObjects qs, (err, body) ->
        console.log util.inspect body
        process.exit 0

    qs =
        json:true
        object: "event"
        tag: "bangarang"
        includes: 'event_KEY,Reference_Name'
    api.getTaggedObjects qs, (err, body) ->
    	console.log util.inspect body
    	process.exit 0
