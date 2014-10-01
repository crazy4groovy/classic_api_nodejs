cred        = require '../config/sample'
util		= require "util"
{API}       = require "../lib/api"

api         = new API cred

# Retrieve actions tagged with `bangarang`.  Note that
# this just returns the first batch of actions if there
# are more than 500.
#
api.authenticate (err, res, body) ->
    if err?
        console.log "Authentication error: #{results.message}"
        process.exit 1
    qs = 
        json:true
        object: "action"
        tag: "bangarang"
        includes: 'action_KEY,Reference_Name'
    api.getTaggedObjects qs, (err, res, body) ->
    	console.log util.inspect body
    	process.exit 0
