_       = require 'underscore'
async   = require 'async'
csv     = require 'to-csv'
fs      = require 'fs'
opts    = require 'commander'
request = require 'request'
{API}   = require '../src/api'

# Class to locate international supporters with states, then convert the states
# to state names.  We need this because Salsa stores numeric state abbreviations
# that can't be used for any real purpose.
#
# Input is via the API.  Output is a CSV containing
#
# *supporter_KEY
# *old_State
# *State
#
# Note on the URL:
#
#''$.getJSON("/o/50973/p/salsa/common/international/public/country/eng/countryData.sjs?country=" + country_name + "&jsoncallback=?", function(data) {
#});''
#
class I18nStateExporter
    # Constructor.  Built a new instance of this class using the provided runtime `options`.
    #
    # @param           [Object]  options          Options object
    # @option options  [String]  email            campaign manager email address
    # @option options  [String]  password         campaign manager password
    # @option options  [String]  hostname         URL_HOST for the database
    # @option options  [String]  organizationKEY  organizationKEY to log into
    # @option options  [String]  outputPath       output for storing the CSV results
    #
    constructor: (@options) ->
        @api = new API @options
        @cache = {}

    # Function to return all records that match the provided
    # `conditions`.  Records are filtered after retrieveal to
    # return the ones with a non-empty `Zip` field.
    #
    # @param  [String]    condition  the condition for retrieving records
    # @param  [Function]  cb         callback to handle (`err`, `record`)
    #
    # @usage
    #
    # coffee i18n_state_exporter.coffee
    #   --email whoever@what.ever
    #   --password secret-password
    #   --hostname whatever.salsalabs.com
    #   --organization-key 1234
    #   --output-path results.csv
    #
    # @note
    #
    # Records are returned as a JSON list of objects of this format:
    #
    # { supporter_KEY: '55484631',
    #    State: 'GB+01',
    #    Country: 'GB',
    #    key: '55484631',
    #    object: 'supporter'
    # }
    #
    fetch: (condition, cb) =>
        queries = 
            object: "supporter"
            condition: condition
            include: "State,Country"
            limit:
                offset: 0
                count: 10000
            json: true
    
        @api.getObjects queries, (err, results) ->
            return cb err, results if err?
            return cb null, null unless results?.length > 0
            cb null, results.filter (r) -> r.State?.trim().length > 0
    
    # Function to populate move the `State` field to the `oldState` field, then
    # read a new value for `State`.  This translates something like 'GB+01' to 'Avon'.
    # Returns a list of modified records.
    # 
    # @param  [Array<Object>]  records  list of records to modify
    # @param  [Function]       cb       callback to handle (`err`, `modifiedRecords`)
    #
    populate: (records, cb) =>
        console.log "populate: #{records.length} records"
        return cb null, records unless records?.length > 0
        async.mapLimit records, 1, @populateOne, cb

    # Function to populate a single record using Salsa's country call.
    #
    # @param  [Object]    record  Record to populate
    # @param  [Function]  cb      Function to return (`err`, `record`)
    #
    populateOne: (record, cb) =>
        tasks = []
        tasks.push (cb)  =>
            return cb null if @cache.hasOwnProperty record.Country
            @readCountry record.Country, cb

        tasks.push (cb) =>
            record.oldState = record.State
            record.State = @cache[record.Country][record.State.split('+')[1]]
            cb null

        async.waterfall tasks, (err, results) ->
            #console.log "populateOne: returning record", record
            return cb err if err?
            cb null, record
    
    # Read a country.  Output gets stuffed into the cache.
    #
    # @param  [String]    country  country of interest
    # @param  [Function]  cb       callback to handle (`err`)
    #
    readCountry: (country, cb) =>
        appUrl = "https://#{@options.hostname}/o/#{@options.organizationKey}"
        appUrl = appUrl + "/p/salsa/common/international/public/country/eng/countryData.sjs?country=#{country}&jsoncallback=whatever"
        opts = 
            url: appUrl
            method: "GET"
            json: true
        request opts, (err, resp, body) =>
            return cb err if err?
            # Unwrap the blasted `jasoncallback`, which is requred by the call to `countryData.js`
            body = RegExp("whatever\((.+?)\)$").exec(body)[1]
            body = eval body
            @cache[country] = body.states.reduce @reduceCountry, {}
            cb null

    # Method called by `Array.reduce` to populate an Object with state records. State
    # records are keyed by the state `code` containing state `name`.
    #
    # Input record looks like this:
    #
    # ``` {"code":"01","name":"Badakhshan"} ```
    #
    # Output records are added to `output` as object items such that
    #
    # ``` output[code] === name
    # 
    # @param          [Object]         output  object to hold each record
    # @param          [Object]         state   record to use to populate `output`
    # @option  state  [String]         code    state code, usually two digits
    # @option  state  [String]         name    state name
    # @return         [Object]         returns `output`
    #
    reduceCountry: (output, state) -> output[state.code] = state.name; output

    # Main function.  Reads the records, updates the state and writes
    # the .csv output.
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
            @fetch 'Country IS NOT EMPTY', (err, records) ->
                return cb err, null if err?
                console.log 'run: ', records.length, 'Country IS NOT EMPTY'
                records = records.filter (r) -> r.Country != 'ot'
                console.log 'run: ', records.length, "Country is not 'other'"
                records = records.filter (r) -> r.Country != 'US'
                console.log 'run: ', records.length, "Country is not 'US'"
                records = records.filter (r) -> r.State.indexOf('+') != -1
                console.log 'run: ', records.length, "records needs lookup"
                cb null, records
                
        tasks.push (records, cb) =>
            records = records.sort (a, b) ->
                switch
                    when a.State < b.State then -1
                    when a.State == b.State then -1
                    when a.State > b.State then 1
            @populate records, cb

        tasks.push (records, cb) =>
            # Scrub the records to remove unwanted fields.
            records = records.map (r) -> delete r[k] for k in 'object,key,Country'.split ','; r
            
            text = csv(records)
            console.log "run: writing", text
            fs.writeFileSync @options.outputPath, csv(records), encoding: "UTF-8"
            console.log "run: done, #{records.length} records written to #{@options.outputPath}"
            cb null, records

        async.waterfall tasks, (err, results) ->
            throw err if err?
            process.exit 0

# Collect the options from the command line and get to work.
#
opts
    .description('Create a .csv file of supporter_KEYS and international state names')
    .version('1.0')
    .option('--email <email>', '(Required) campaign manager email address', String, null)
    .option('--password <password>', '(Required) campaign manager password', String, null)
    .option('--hostname <email>', '(Required) API_HOST for the campaign manager', String, null)
    .option('--organization-key <number>', '(Requred) organization_KEY to use to read', Number, null)
    .option('--output-path <filename>', '(Required) filename to save the output into', String, './state_export.csv')
opts.parse process.argv

#unless opts.email?.length > 0 and opts.password?.length > 0 and opts.hostname?.length > 0 and opts.filename?.length > 0 and opts.organizationKey > 0
#console.log "ALL parameters are required!"
#opts.help()

new I18nStateExporter(opts).run (err, whatever) ->
    console.log err
    console.log whatever
    process.exit 0

# salsa4/50973 email rabbit-hats