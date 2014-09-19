cred = require '../config/private_credentials'
{API} = require 'coffee_salsa'

qs =
    object: 'supporter'
    key: 123456
    First_Name: 'Bob'
    Last_Name: 'Johnson'
    Email: 'bob@john.son'
api = new API cred
api.save qs, (err, results) ->
    throw err if err?
    console.log "table #{qs.object} saving", qs, "results: ", results
    process.exit 0

