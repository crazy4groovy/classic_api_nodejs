_       = require 'underscore'
async   = require 'async'
request = require("request").defaults({jar: true})
util    = require "util"

class API
    # Create a new instance of the API class.
    #
    # @param          [Object] options          login options, often retrieved from a JSON file (hint)
    # @option options [String] hostname         the URL of the Salsa host for your organization
    # @option options [String] email            campaign manager's email address
    # @option options [String] password         campaign manager's password
    # @option options [Number] organization_KEY (optional) organization_KEY
    # @option options [Number] chapter_KEY      (optional) chapter_KEY
    #
    # @example
    #   options = 
    #       hostname: 'larry.salsalabs.com'
    #       email: 'larry@lounge.lizard'
    #       password: 'larry-larry-larry'
    #   api = new API options
    #
    constructor: (@options) ->

    # Performs authentication for using Salsa campaign manager credentials.
    # Results are returned through the callback.
    #
    # @param [Function] cb callback to return (`err`, `json_response`)
    #
    # @example
    #   api.authenticate, (err, results) ->
    #       throw err if err?
    #       console.log "Authentication results are #{util.inspect results}"
    #
    # @see  https://help.salsalabs.com/entries/23529436-Authenticating
    #
    authenticate: (cb) ->
        opts =
            url: "https://#{@options.hostname}/api/authenticate.sjs"
            qs:
                email: @options.email
                password: @options.password
                json: true
            method: "GET"
            json: true
        opts.qs.organization_KEY = @options.organization_KEY if @options.organization_KEY?
        opts.qs.chapter_KEY = @options.chapter_KEY if @options.chapter_KEY?
        request opts, (err, res, body) ->
            return cb err, null if err?
            return cb body.status, body if body.status != 'success'
            cb null, body

    # Delete an object using a callback.
    #
    # @param         [Object]   qs      specification of the object to delete
    # @option qs     [String]   object  table name to use for deletion
    # @option qs     [Number]   key     the primary key (typically "object"_KEY) to delete
    #
    # @param         [Function] cb      functioned called with (err, results)
    #
    # @example
    #   qs = 
    #       object: 'donation'
    #       key: 1234567
    #   api.deleteObject qs, (err, results) ->
    #       raise err if err?
    #       console.log "delete returned", results
    #
    # @see https://help.salsalabs.com/entries/23530453-Saving-Data-to-Salsa
    #
    deleteObject: (qs, cb) ->
        opts =
            url: "https://#{@options.hostname}/delete"
            qs: qs
            method: "GET"
            json: true
        request opts, (err, res, body) ->
            return cb err, null if err?
            cb null, body

    # Return the schema layout for a table.
    #
    # @param        [Object]    qs      specification of the table to describe
    # @option  qs   [String]    object  table name to describe
    # @param        [Function]  cb      function called with (err, results)
    #
    # @example
    #   qs = object: 'tag'
    #   api.describeObject qs, (err, results) ->
    #       throw err if err?
    #       console.log "table #{qs.object} layout is", results
    #
    # @see https://help.salsalabs.com/entries/23537918-Getting-data-from-Salsa#describe2
    #
    describeObject: (qs, cb) ->
        opts =
            url: "https://#{@options.hostname}/api/describe2.sjs"
            qs: qs
            method: "GET"
            json: true
        request opts, cb

    # Retrieve the number of records for a table. The `qs` parameter contains the options
    # described in documentation (object, key, conditions, etc.).
    #
    # @param        [Object]    qs      specification of the table to count
    # @option  qs   [String]    object  table name
    # @param        [Function]  cb      function called with (err, results)
    #
    # @example
    #   qs =
    #       object: 'supporter'
    #       countColumn: 'supporterKey'
    #       limit: '20'
    #       condition: 'First_Name!=Bob'
    #   api.getCount qs, (err, results) ->
    #       throw err if err?
    #       console.log "table #{qs.object} count returned", results
    #
    # @see https://salsasupport.zendesk.com/entries/23537918-Getting-Data-From-Salsa#getCount
    #
    getCount: (qs, cb) ->
        opts =
            url: "https://#{@options.hostname}/api/getCount.sjs"
            qs: qs
            method: 'GET'
            json: true
        request opts, cb

    # Read objects from a table.  The `qs` parameter contains the options
    # described in documentation (object, key, conditions, etc.).
    #
    # @param    [Object]    qs  Query strings as an object
    # @param    [Function]  cb  Function that will receive (err, records)
    #
    # @example Read 10 records starting at the 1000'th record and display offsets and Email addresses.
    #   qs = 
    #       object: 'supporter'
    #       limit:
    #           offset: 1000
    #           count: 10
    #       json: true
    #   api.getObjects qs, (err, results) ->
    #       throw err if err?
    #       console.log "count:", records.length
    #       console.log i, records[i].Email for i in [0...records.length]
    #       process.exit 0
    #
    getObjects: (qs, cb) ->
        opts =
            url: "https://#{@options.hostname}/api/getObjects.sjs"
            qs: qs
            method: 'GET'
            json: true
        @_readFully opts, cb

    # Read objects from a table that have a specific tag.  The `qs` parameter
    # contains the options described in documetation (object, tag,  etc.).
    #
    # @param            [Object]    qs  Query strings as an object
    # @option   qs      [String]    tag The tag value of interest (in addition to the usual parameters.)
    # @param            [Function]  cb  Function that will receive (err, records)
    #
    getTaggedObjects: (qs, cb) ->
        opts =
            url: "https://#{@options.hostname}/api/getTaggedObjects.sjs"
            qs: qs
            method: "GET"
            json: true
        @_readFully opts, cb

    # Private method to read all records for a URL.  This method handles
    # Salsas 500-record batches that Salsa returns.
    #
    # @param         [Object]        opts    Options to provide to request
    # @option   opts [URL,String]    url     URL to use to read
    # @option   opts [Object]        qs      Queries presented as an object (will be modified to handle batching)
    # @option   opts [String]        method  Typically "GET"...
    # @option   opts [Boolean]       json    Request treats this as a JSON call.  Typically true.
    # @param         [Function]      cb      Callback, should expect (err, records)
    # @private
    #
    # @note
    # The 'limit' parameter in qs describes the records to read.  If it is missing
    # from the call, then a default 'limit' parameter is provided.  The fields
    # for a 'limit' parameter are as follows:
    #
    # * offset  The offset in the database to start reading, default is 0 (zero).
    # * count   The number of records to return.  Default is to read all records.
    #
    _readFully: (opts, cb) ->
        localOpts = _.clone opts
        localOpts.qs.limit = {} unless localOpts.limit?
        throw new Error "Error: limit must be an object, not a #{typeof localOpts.qs.limit}!" if typeof localOpts.qs.limit != 'object'
        limit = _.clone opts.qs.limit
        limit.offset = 0 unless limit.offset?
        limit.offset = Math.max limit.offset, 0
        limit.count = 500 unless limit.count?

        # The qs parameter contains the queries that need to be passed to
        # Salsa in the URL.  Salsa needs a 'limit' parameter in the query
        # string.  The limit parameter is described in SalsaCommons.

        records = []
        inner = (cb) ->
            localOpts.qs.limit = "#{limit.offset},#{limit.count}"
            # Force out put to be encoded as JSON
            localOpts.qs.json = true
            request localOpts, (err, response, body) ->
                return cb err if err?
                # Body is a JSON-formatted list of records
                limit.count = body.length
                limit.offset = limit.offset + body.length
                records.push body
                cb null

        # @returns true if all records have been read
        working = () ->
          limit.count > 0

        # "Do until done" for reading records.
        async.doWhilst inner, working, (err) ->
          return cb err, null if err?
          cb null, _.flatten records

    # qs is {object: whatever, key=0|Number, record_field_1: whatever, record_field_2: whatever, etc.}   
    save: (qs, cb) ->
        opts =
            url: "https://#{@options.hostname}/save"
            qs: qs
            method: "GET"
            json: true
        request opts, cb

module.exports.API = API