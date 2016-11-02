{API} = require '../lib/api'
options = 
    hostname: 'wfc2.wiredforchange.com'
    email: 'lounge@lizard.bizi'
    password: 'larry-larry-larry'

api = new API options
api.authenticate (err) ->
    throw "Authentication err #{err}" if err?
    queries = 
        object: "supporter"
        First_Name: "Alpha"
        Last_Name: "Pie"
        Email: "alpha@pie.bizi"
        Phone: "333-444-5555"
    api.save queries, (err, resp, body) ->
        console.log "/save error is #{err}"?
        console.log "body", body
        throw err if err?
        process.exit 0