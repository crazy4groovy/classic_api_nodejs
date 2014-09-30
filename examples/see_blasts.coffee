cred            = require '../config/sample'
request         = require 'request'
util            = require 'util'
{API}           = require '../lib/api'

api             = new API cred

api.authenticate (err, body) ->
    throw err if err?
    console.log body.message
    api.getObjects object: 'email_blast', include: "email_blast_KEY", json:true, (err, body) ->
        console.log util.inspect body
        process.exit 0
