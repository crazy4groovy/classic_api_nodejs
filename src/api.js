(function () {
  var API, async, request, util, _;

  _ = require("underscore");

  async = require("async");

  request = require("request").defaults({
    jar: true,
  });

  util = require("util");

  API = (function () {
    function API(conf) {
      this.conf = conf;
    }

    API.prototype.authenticate = function (cb) {
      const opts = {
        url: "https://" + this.conf.hostname + "/api/authenticate.sjs",
        qs: {
          json: true,
          email: this.conf.email,
          password: this.conf.password,

          organization_KEY: this.conf.organization_KEY || undefined,
          chapter_KEY: this.conf.chapter_KEY || undefined
        },
        method: "GET",
        json: true,
      };
      return request.post(opts, function (err, res, body) {
        if (err != null) return cb(err, null);

        if (body.status !== "success") {
          return cb(body.status, body);
        }

        return cb(null, body);
      });
    };

    API.prototype.deleteObject = function (qs, cb) {
      const opts = {
        url: "https://" + this.conf.hostname + "/delete",
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
      const opts = {
        url: "https://" + this.conf.hostname + "/api/describe2.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return request.post(opts, cb);
    };

    API.prototype.getCount = function (qs, cb) {
      const opts = {
        url: "https://" + this.conf.hostname + "/api/getCount.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return request.post(opts, cb);
    };

    API.prototype.getObject = function (qs, cb) {
      const opts = {
        url: "https://" + this.conf.hostname + "/api/getObject.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return request.post(opts, cb);
    };

    API.prototype.getObjects = function (qs, cb) {
      const opts = {
        url: "https://" + this.conf.hostname + "/api/getObjects.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return this._allResultPages(opts, cb);
    };

    API.prototype.getTaggedObjects = function (qs, cb) {
      const opts = {
        url: "https://" + this.conf.hostname + "/api/getTaggedObjects.sjs",
        qs: qs,
        method: "GET",
        json: true,
      };
      return this._allResultPages(opts, cb);
    };

    API.prototype._allResultPages = function (opts, cb) {
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
      const opts = {
        url: "https://" + this.conf.hostname + "/save",
        form: qs,
        json: true,
      };
      return request.post(opts, cb);
    };

    return API;
  })();

  module.exports.API = API;
}.call(this));
