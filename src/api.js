(function () {
  var API, async, request, util, _;

  _ = require("underscore");

  async = require("async");

  request = require("request").defaults({
    jar: true,
  });

  util = require("util");

  API = (function () {
    function API(_at_options) {
      this.options = _at_options;
    }

    API.prototype.authenticate = function (cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/api/authenticate.sjs",
        qs: {
          email: this.options.email,
          password: this.options.password,
          json: true,
        },
        method: "GET",
        json: true,
      };
      if (this.options.organization_KEY != null) {
        opts.qs.organization_KEY = this.options.organization_KEY;
      }
      if (this.options.chapter_KEY != null) {
        opts.qs.chapter_KEY = this.options.chapter_KEY;
      }
      return request.post(opts, function (err, res, body) {
        if (err != null) return cb(err, null);

        if (body.status !== "success") {
          return cb(body.status, body);
        }
        return cb(null, body);
      });
    };

    API.prototype.deleteObject = function (qs, cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/delete",
        qs: qs,
        method: "GET",
        json: true,
      };
      return request.post(opts, function (err, res, body) {
        if (err != null) return cb(err, null);

        return cb(null, body);
      });
    };

    API.prototype.describeObject = function (qs, cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/api/describe2.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return request.post(opts, cb);
    };

    API.prototype.getCount = function (qs, cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/api/getCount.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return request.post(opts, cb);
    };

    API.prototype.getObject = function (qs, cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/api/getObject.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return request.post(opts, cb);
    };

    API.prototype.getObjects = function (qs, cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/api/getObjects.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return this._readFully(opts, cb);
    };

    API.prototype.getTaggedObjects = function (qs, cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/api/getTaggedObjects.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return this._readFully(opts, cb);
    };

    API.prototype._readFully = function (opts, cb) {
      var inner, limit, localOpts, records, working;
      localOpts = _.clone(opts);
      if (localOpts.limit == null) {
        localOpts.qs.limit = {};
      }
      if (typeof localOpts.qs.limit !== "object") {
        throw new Error(
          "Error: limit must be an object, not a " +
            typeof localOpts.qs.limit +
            "!"
        );
      }
      limit = _.clone(opts.qs.limit);
      if (limit.offset == null) {
        limit.offset = 0;
      }
      limit.offset = Math.max(limit.offset, 0);
      if (limit.count == null) {
        limit.count = 500;
      }
      records = [];
      inner = function (cb) {
        localOpts.qs.limit = limit.offset + "," + limit.count;
        console.log("inner: localOpts", localOpts);
        localOpts.qs.json = true;
        return request.post(localOpts, function (err, response, body) {
          if (err != null) return cb(err);

          if (!(body && body.length > 0)) {
            body = [];
          }
          limit.count = body.length;
          limit.offset = limit.offset + body.length;
          records.push(body);
          return cb(null);
        });
      };
      working = function () {
        return limit.count > 0;
      };
      return async.doWhilst(inner, working, function (err) {
        if (err != null) return cb(err, null);

        return cb(null, _.flatten(records));
      });
    };

    API.prototype.save = function (qs, cb) {
      var opts;
      opts = {
        url: "https://" + this.options.hostname + "/save",
        form: qs,
        json: true,
      };
      return request.post(opts, cb);
    };

    return API;
  })();

  module.exports.API = API;
}.call(this));
