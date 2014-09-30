cred        = require '../config/sample'
request 	= require "request"
util		= require "util"
{API}       = require "../lib/api"

api         = new API cred

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
