_       = require 'underscore'
async   = require 'async'
config  = hostname: 'org.salsalabs.com', email: 'aleonard@salsalabs.com', password: 'caifornia'
sprintf = require 'sprintf'
{API}   = require '../lib/api'

api = new API config

# This app looks a lot better if we use an async waterfall.
#
tasks = []

# Authentication.
#
# @param [Function] cb callback to handle (`err`, `loginResults`)
# 
tasks.push (cb) ->
    api.authenticate cb

# Retrieve a list of recipient keys.    Errors are noisily fatal.
# 
# @param [String]    loginResults  object containing successful login info
# @param [Function]  cb            callback to handle (`err`, `recipientList`)
#
tasks.push (loginResults, cb) ->
    console.log "loginResults", loginResults
    cb null

tasks.push (cb) ->
    api.save

# Delete the custom recipients provided in the call.
#
# @param [Array<Object>]  records  list of custom recipient records, possibly empty
# @param [Function]       cb       callback to handle (`err`, `records`)
#
tasks.push (records, cb) ->
    console.log "records", records
    return cb null, records unless records.length > 0

    keys = (record.donation_KEY for record in records).filter (k) -> parseFloat(k) < 3931457
    console.log keys
    cb null, records

    # Delete the provided key from recipient.
    #
    # @param [String]    key  primary key to delete
    # @param [Function]  cb   callback to handle (`err`, `results`)
    #
    # deleter = (key, cb) ->
    #     qs = 
    #         object: 'recipient'
    #         key: key
    #     api.deleteObject qs, cb

    # async.mapSeries keys, deleter, (err, results) ->
    #     return cb err, null if err?
    #     return cb null, records

async.waterfall tasks, (err, results) ->
    if err?
        console.log "Error! ", results
        process.exit 1
    if results? and results.length > 0
        console.log "Removed these custom recipients:"
        (console.log sprintf "%-10s %-20s %10.2f", r.donation_KEY, r.Email, r.amount for r in results)
    else
        console.log "No donations to delete!"
    process.exit 0
