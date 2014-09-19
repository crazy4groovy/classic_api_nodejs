cred    = require '../config/private_credentials'
request = require 'request'
util    = require 'util'
{API}   = require 'coffee_salsa'

api = new API cred
api.authenticate (err, body) ->
    throw err if err?
    console.log body.message

    queries =
        condition: 'amount>1'
        include: 'Transaction_Date,First_Name,Last_Name,amount'
        json:    true
        limit:
            offset: 0
            count: 500
        object:  'donation'
        orderBy: 'Last_Name,First_Name,Email'

    api.getObjects queries, (err, res, donations) ->
        throw err if err?
        console.log "Read returned #{donations.length} objects."
        for donation in donations
            console.log "#{donation.Transaction_Date} #{donation.First_Name} #{donation.Last_Name} #{donation.amount}"

        process.exit 0
