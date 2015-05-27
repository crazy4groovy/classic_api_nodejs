_       = require 'underscore'
async   = require 'async'
opts    = require 'commander'
request = require 'request'
{API}   = require '../src/api'

# Class to list `supporter_KEY`, `Email` and tags for a supporter. The 
# `supporter_KEY` is provided in the command line.
#
class SeeSupporterStatus
    # Constructor.  Built a new instance of this class.
    #
    # @param  [Object]  opts           command-line options
    # @opts   [String]  email          campaign manager email address
    # @opts   [String]  password       campaign manager password
    # @opts   [String]  hostname       URL_HOST for the database
    # @opts   [String]  supporter_KEY  search for tags for this supporter key
    #
    constructor: (@opts) ->
        @api = new API @opts

    # Function to return all records with supporter_KEYs in the list of keys
    # provided in the constructor.
    #
    # @param  [Function]  cb         callback to handle (`err`, `records`)
    #
    # @note Records are returned as a JSON list of objects of this format:
    #
    # { supporter_KEY: '55484631',
    #    Status: '',
    #    key: '55484631',
    #    object: 'supporter'
    # }
    #
    fetch: (cb) =>
        joinObject = "supporter(supporter.supporter_KEY=tag_data.table_key)tag_data(tag_KEY)tag"
        joinCondition = "suporter.supporter_KEY=#{@opts.supporter_KEY}&amp;tag_data.database_table_KEY=142"
        queries = 
            object: joinObject
            condition: joinObject
            include: "supporter.Email,tag.prefix,tag.tag"
            limit:
                offset: 0
                count: 100000
            json: true
    
        @api.getObjects queries, cb

    # Main function.  Reads the records and displays them as a tab-delimited file.
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
            @fetch (err, records) ->
                return cb err, null if err?
                console.log records
                process.exit 1

                records = _.sortBy records, (r) -> r.supporterKey
                (console.log r.supporter_KEY, r.Status for r in records)

        async.waterfall tasks, (err, results) ->
            throw err if err?
            process.exit 0

# Collect theoptsfrom the command line and get to work.
#
opts
    .description('Display the tags for a supporter.')
    .version('1.0')
    .option('--email <email>', '(Required) campaign manager email address', String, null)
    .option('--password <password>', '(Required) campaign manager password', String, null)
    .option('--hostname <email>', '(Required) API_HOST for the campaign manager', String, null)
    .option('--supporter_KEY <key>', '(Required) supporter_KEY to use to find tags', null)
opts.parse process.argv

unless opts.email?.length > 0 and opts.password?.length > 0 and opts.hostname?.length > 0 and opts.supporter_KEY?.length > 0
    console.log "ALL parameters are required!"
    opts.help()

new SeeSupporterStatus(opts).run (err, whatever) ->
    console.log err
    #console.log whatever
    process.exit 0
