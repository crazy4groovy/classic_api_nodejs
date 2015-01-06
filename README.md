# API Playground

## Description
The Salsa API in a CoffeeScript class.  Plus lots of exciting and informative examples!

## Dependencies

* [Async](https://github.com/caolan/async) for handing synchronicity in an asynchronous world
* [Coffeescript](http://coffeescript.org/) Coffeescript engine that uses Node.js
* [JSDom](https://github.com/tmpvar/jsdom) for parsing HTML
* [Node.js](http://nodejs.org/api/) Javascript engine
* [Request](https://github.com/mikeal/request) for reading and writing web resources
* [Underscore](http://underscorejs.org/) *awesome* collection of array and object manipulation functions

Other less-used dependencies are listed in `package.json`

## Installation

    npm install api.[[version]].tgz

## Examples

### Initialization
```coffee
    {API}    = require 'api'
    util     = require 'util'
    options = 
        hostname: 'larry.salsalabs.com'
        email   : 'larry@lounge.lizard'
        password: 'larry-larry-larry'

    api = new API options
```
An object can also be installed with a JSON object in the source tree.  For example, for a file named `config/myorg.json`
with these contents:
``` javascript
{
    "hostname":  "something.salsalabs.com",
    "email":  "whoever@whatever.com",
    "password":  "extra-super-secret-password-that's-not-this-password"
 }
```
Instantiation example:
``` coffee
    {API}    = require 'api'
    myorg    = require 'config/myorg.json'

    api = new API myorg
```
### Authentication
```coffee
    api.authenticate (err, response) ->
        if err? or response.status != 'success'
            console.log "Unable to login, #{response}"
            process.exit 0
```
### Read a record
```coffee
    api.getObject object: 'supporter', key: 123456, json:true, (err, supporter) ->
        throw err if err?
        console.log "Supporter #{supporter.supporter_KEY} has email #{supporter.Email}"
```
***or***
```coffee
    queries =
        object: 'supporter'
        key:    '123456'
        json:   true

    api.getObject queries, (err, supporter) ->
        throw err if err?
        console.log "Supporter #{supporter.supporter_KEY} has email #{supporter.Email}"
```
### Save a record
```coffee
    api.save supporter, (err, response) ->
        throw err if err?
        console.log "Saving supporter returned #{util.inspect response}"
        process.exit 0
```
### Read many records
```coffee
    queries =
        condition: 'amount>500'
        include: 'Transaction_Date,First_Name,Last_Name,amount'
        json:    true
        limit:   '10,20'
        object:  'donation'
        orderBy: 'Last_Name,First_Name,Email'

    api.getObjects queries, (err, donations) ->
        throw err if err?
        console.log "Read returned #{donations.length} objects."
        for donation in donations
            console.log "#{donation.Transaction_Date} #{donation.First_Name} #{donation.Last_Name} #{donation.amount}"
```
***Note:*** Version 1.x can only handle a single _condition_.

### Read tagged records
```coffee
    supporter_KEY = 123456
    queries =
        json:      true
        object:    "action"
        tag:       "bangarang"
        includes:  'action_KEY,Reference_Name'
        condition: 'supporter_KEY=#{supporter_KEY}'

    api.getTaggedObjects queries, (err, actions) ->
        throw err if err?
        console.log "Read returned #{actions.length} objects."
        for action in actions
            console.log "#{action_KEY} #{action.Reference_Name}"
```
***Note:*** Version 1.x can only handle a single _condition_.

***Note:*** _includes_ is ignored.  A case is open to fix this problem.

## Documentation

Documentation is created by 'codo', and can can be found in the repository in the 'doc' directory.
Markup documentation can be found [here](https://help.github.com/articles/github-flavored-markdown).

