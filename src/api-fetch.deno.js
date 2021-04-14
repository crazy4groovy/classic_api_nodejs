#!/usr/bin/env -S deno run --allow-all --unstable
// deno run --allow-all --unstable https://gist.githubusercontent.com/crazy4groovy/0436a0fbc31b3acaee4dc93adb6be17b/raw/salsa-classic-client.deno.js
import * as fs from "https://deno.land/std@0.92.0/fs/mod.ts";
import * as path from "https://deno.land/std@0.92.0/path/mod.ts";
import { wrapFetch } from "https://deno.land/x/another_cookiejar@v4.0.0/mod.ts";

const fetch = wrapFetch();

let [basedir] = Deno.args;
if (!basedir || !fs.existsSync(basedir)) throw new Error("DIR doesn't exist");
basedir = path.resolve(".", basedir);

if (!fs.existsSync(path.join(basedir, "config.json"))) {
  console.error("CONFIG FILE missing");
  Deno.exit(1);
}
const conf = JSON.parse(
  Deno.readTextFileSync(path.join(basedir, "config.json"))
);

let isAuthed = false;

const _makeBody = (qs = {}) => {
  const body = new URLSearchParams();
  body.append("json", true);
  for (const k in qs) {
    if (qs[k] == null) continue;
    body.append(k, qs[k]);
  }
  return body;
};

const _makeUrl = (authQs = conf, endpoint) =>
  `https://${authQs.hostname}/api/${endpoint}`;

const _miss = (msg) => {
  throw new Error("Missing: " + msg);
};

const auth = async (authQs = conf) => {
  if (!authQs.hostname) _miss("hostname");
  if (isAuthed === authQs.hostname) return;

  const opts = {
    method: "POST",
    body: _makeBody({
      email: authQs.email || _miss("email"),
      password: authQs.password || _miss("password"),
      organization_KEY: authQs.organization_KEY || _miss("organization_KEY"),
      chapter_KEY: authQs.chapter_KEY,
    }),
  };
  await fetch(_makeUrl(authQs, "authenticate.sjs"), opts);
  isAuthed = authQs.hostname;
  console.log("AUTHED! @", new Date().toLocaleString());
};

const getCount = async function (qs, authQs) {
  await auth(authQs);
  const opts = {
    method: "POST",
    body: _makeBody(qs),
  };
  return fetch(_makeUrl(authQs, "getCount.sjs"), opts).then((r) => r.json());
};

const describeObject = async function (qs, authQs) {
  await auth(authQs);
  const opts = {
    method: "POST",
    body: _makeBody(qs),
  };
  return fetch(_makeUrl(authQs, "describe2.sjs"), opts).then((r) => r.json());
};

const deleteObject = async function (qs, authQs) {
  await auth(authQs);
  const opts = {
    method: "POST",
    body: _makeBody(qs),
  };
  return fetch(_makeUrl(authQs, "delete.sjs"), opts).then((r) => r.json());
};

const getObject = async function (qs, authQs) {
  await auth(authQs);
  const opts = {
    method: "POST",
    body: _makeBody(qs),
  };
  return fetch(_makeUrl(authQs, "getObject.sjs"), opts).then((r) => r.json());
};

const getObjectsGen = async function* (qs, authQs) {
  await auth(authQs);
  yield* _pagedFetchGen(_makeUrl(authQs, "getObjects.sjs"), _makeBody(qs));
};

const getTaggedObjectsGen = async function* (qs, authQs) {
  await auth(authQs);
  yield* _pagedFetchGen(
    _makeUrl(authQs, "getTaggedObjects.sjs"),
    _makeBody(qs)
  );
};

async function* _pagedFetchGen(url, body) {
  // uses "offset" and "count" params
  const limit = {
    offset: Math.max(Number(body.get("offset")), 0) || 0,
    count: Math.max(Number(body.get("count")), 0) || 500,
  };
  body.delete("offset");
  body.delete("count");

  const opts = {
    method: "POST",
    body,
  };
  let resp;
  do {
    body.delete("limit");
    body.append("limit", `${limit.offset},${limit.count}`);
    resp = await fetch(url, opts).then((r) => r.json());
    yield resp;
    limit.count -= resp.length;
    limit.offset += resp.length;
  } while (limit.count > 0 && resp.length > 0);
}

export default {
  auth, // optional
  getCount,
  describeObject,
  deleteObject,
  getObject,
  getObjectsGen,
  getTaggedObjectsGen,
};

(async function () {
  console.log("Sample", new Date().toLocaleString());

  // const o = await getObject({ object: "supporter", key: 1234567 });
  // console.log(o);

  const getObjects = getObjectsGen({
    condition: "amount>100",
    count: 600,
    include: "Transaction_Date,First_Name,Last_Name,amount",
    object: "donation",
    offset: 10,
    orderBy: "Last_Name,First_Name,Email",
  });
  // const { value : d } = await getObjects.next();
  // console.log(d);
  for await (const r of getObjects) {
    console.log(r.length);
  }
})();
