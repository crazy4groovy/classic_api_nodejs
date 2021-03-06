cred            = require '../config/sample'
request         = require 'request'
util            = require 'util'
{API}           = require '../lib/api'

api             = new API cred

api.authenticate (err, body) ->
    throw err if err?
    console.log body.message

    queries =
        condition: 'amount>500'
        include: 'Transaction_Date,First_Name,Last_Name,amount'
        json:    true
        limit:   '10,20'
        object:  'donation'
        orderBy: 'Last_Name,First_Name,Email'

    api.getObjects queries, (err, res, donations) ->
        throw err if err?
        process.exit 0 unless donations?
        console.log "Read returned #{donations.length} objects."
        for donation in donations
            console.log "#{donation.Transaction_Date} #{donation.First_Name} #{donation.Last_Name} #{donation.amount}"

        process.exit 0
