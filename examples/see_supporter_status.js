(function () {
  var API,
    SeeSupporterStatus,
    async,
    opts,
    request,
    _,
    _ref,
    _ref1,
    _ref2,
    _ref3,
    __bind = function (fn, me) {
      return function () {
        return fn.apply(me, arguments);
      };
    };

  _ = require("underscore");

  async = require("async");

  opts = require("commander");

  request = require("request");

  API = require("../src/api").API;

  SeeSupporterStatus = (function () {
    function SeeSupporterStatus(opts) {
      this.opts = opts;
      this.fetch = __bind(this.fetch, this);
      this.api = new API(this.opts);
    }

    SeeSupporterStatus.prototype.fetch = function (cb) {
      var keys, queries;
      keys = this.opts.keys.replace(/\s+/, "");
      queries = {
        object: "supporter",
        condition: "supporter_KEY IN " + keys,
        include: "Status",
        limit: {
          offset: 0,
          count: 100000,
        },
        json: true,
      };
      return this.api.getObjects(queries, cb);
    };

    SeeSupporterStatus.prototype.run = function () {
      var tasks;
      tasks = [];
      tasks.push(
        (function (_this) {
          return function (cb) {
            return _this.api.authenticate(function (err, results) {
              if (err != null) {
                return cb(err, results);
              }
              return cb(null, null);
            });
          };
        })(this)
      );
      tasks.push(
        (function (_this) {
          return function (whatever, cb) {
            return _this.fetch(function (err, records) {
              var r, _i, _len, _results;
              if (err != null) {
                return cb(err, null);
              }
              records = _.sortBy(records, function (r) {
                return r.supporterKey;
              });
              _results = [];
              for (_i = 0, _len = records.length; _i < _len; _i++) {
                r = records[_i];
                _results.push(console.log(r.supporter_KEY, r.Status));
              }
              return _results;
            });
          };
        })(this)
      );
      return async.waterfall(tasks, function (err, results) {
        if (err != null) {
          throw err;
        }
        return process.exit(0);
      });
    };

    return SeeSupporterStatus;
  })();

  opts
    .description(
      "Display supporter_KEY and status for each supporter_KEY in the comma-delimited list of keys"
    )
    .version("1.0")
    .option(
      "--email <email>",
      "(Required) campaign manager email address",
      String,
      null
    )
    .option(
      "--password <password>",
      "(Required) campaign manager password",
      String,
      null
    )
    .option(
      "--hostname <email>",
      "(Required) API_HOST for the campaign manager",
      String,
      null
    )
    .option(
      "--keys <keys>",
      "(Required) comma-separated list of supporter_KEYs to use",
      null
    );

  opts.parse(process.argv);

  if (
    !(
      ((_ref = opts.email) != null ? _ref.length : void 0) > 0 &&
      ((_ref1 = opts.password) != null ? _ref1.length : void 0) > 0 &&
      ((_ref2 = opts.hostname) != null ? _ref2.length : void 0) > 0 &&
      ((_ref3 = opts.keys) != null ? _ref3.length : void 0) > 0
    )
  ) {
    console.log("ALL parameters are required!");
    opts.help();
  }

  new SeeSupporterStatus(opts).run(function (err, whatever) {
    console.log(err);
    return process.exit(0);
  });
}.call(this));
