_       = require 'underscore'
async   = require 'async'
opts    = require 'commander'
request = require 'request'
{API}   = require '../src/api'

# Class to populate City and State in supporter records where a record
# has a Zip code.  Records are read from Salsa, populated using Zippopatamus,
# then updated in the Salsa database.
#
# Note on Zippopotamus:
#
# URL: 
#
# http://api.zippopotam.us/us/78701-2526
#
# Response:
#
# {}
#
# URL:
#
# http://api.zippopotam.us/us/78701
#
# Response:
#
# {
#     "post code": "78701",
#     "country": "United States",
#     "country abbreviation": "US",
#     "places": [
#         {
#             "place name": "Austin",
#             "longitude": "-97.7426",
#             "state": "Texas",
#             "state abbreviation": "TX",
#             "latitude": "30.2713"
#         }
#     ]
# }
#
class CityStatePopulator
    # Constructor.  Built a new instance of this class.
    #
    # @param               [Object]  credentials  Credentials object
    # @option credentials  [String]  email        campaign manager email address
    # @option credentials  [String]  password     campaign manager password
    # @option credentials  [String]  hostname     URL_HOST for the database
    #
    constructor: (@credentials) ->
        @api = new API @credentials

    # Function to return all records that match the provided
    # `conditions`.  Records are filtered after retrieveal to
    # return the ones with a non-empty `Zip` field.
    #
    # @param  [String]    condition  the condition for retrieving records
    # @param  [Function]  cb         callback to handle (`err`, `record`)
    #
    # @note Records are returned as a JSON list of objects where
    # each object has this format:
    #
    # { supporter_KEY: '55484631',
         #City: '',
         #State: '',
         #Zip: '79277',
         #key: '55484631',
         #object: 'supporter'
    # }
    #
    fetch: (condition, cb) =>
        queries = 
            object: "supporter"
            condition: condition
            include: "City,State,Zip"
            limit:
                offset: 0
                count: 100000
            json: true
    
        @api.getObjects queries, (err, results) ->
            return cb err, results if err?
            return cb null, null unless results?.length > 0
            cb null, results.filter (r) -> r.Zip?.length > 0
    
    # Function to populate the city and state for a list of supporter records
    # given the ZIP code.  This function presumes that the ZIP code already
    # exists.  Returns a list of modified records.
    # 
    # @param  [Array<Object>]  records  list of records to modify
    # @param  [Function]       cb       callback to handle (`err`, `modifiedRecords`)
    #
    populate: (records, cb) ->
        return cb err, records unless records?.length > 0
        async.mapLimit records, 1, @populateOne, cb

    # Function to populate a single record using Zippopotamus.
    #
    # @param  [Object]    record  Record to populate
    # @param  [Function]  cb      Function to return (`err`, `record`)
    #
    populateOne: (record, cb) =>
        opts = 
            url: "http://www.zippopotam.us/us/#{record.Zip.split('-')[0]}"
            method: "GET"
            json: true
        request opts, (err, resp, results) ->
            throw err if err?
            return cb null, record unless results?.places?.length > 0
            record.City = results.places[0]['place name']
            record.State = results.places[0]['state abbreviation']
            cb null, record
    
    # Main function.  Reads the records, popluates city and state, then
    # writes the modifications back to Salsa.
    #
    # @param  [Function]  cb  function to handle (`err`, `whatever`)
    #
    run: ->
        tasks = []
        tasks.push (cb) =>
            @api.authenticate (err, results) ->
                return cb err, results if err?
                return cb null, null

        tasks.push (whatever, cb) =>
            @fetch 'City IS EMPTY', (err, records) ->
                return cb err, null if err?
                console.log records.length, 'City IS EMPTY'
                cb null, records

        tasks.push (cityRecords, cb) =>
            @fetch 'State IS EMPTY', (err, records) ->
                return cb err, null if err?
                console.log records.length, 'State IS EMPTY'
                cb null,  _.union records, cityRecords

        tasks.push (records, cb) =>
            @populate records, cb

        tasks.push (records, cb) ->
            if records?.length > 0
                (console.log [r.supporter_KEY, r.City, r.State, r.Zip].join "\t" for r in records)
            else
                console.log "Sorry, no qualifying records"
            cb null, records

        async.waterfall tasks, (err, results) ->
            throw err if err?
            process.exit 0

# Collect the credentials from the command line and get to work.
#
opts
    .description('Populate the city and state fields for supporters that have zip codes')
    .version('1.0')
    .option('--email <email>', '(Required) campaign manager email address', String, null)
    .option('--password <password>', '(Required) campaign manager password', String, null)
    .option('--hostname <email>', '(Required) API_HOST for the campaign manager', String, null)
opts.parse process.argv

unless opts.email?.length > 0 and opts.password?.length > 0 and opts.hostname?.length > 0
    console.log "ALL parameters are required!"
    opts.help()

new CityStatePopulator(opts).run (err, whatever) ->
    console.log err
    #console.log whatever
    process.exit 0
