
var _  = require('underscore')
, path = require('path')
, fs = require('fs')
;

var MIGRATE_PATTERN = /^\d+\-/;
var name = path.basename(process.cwd());
var migrates = _.select(fs.readdirSync("migrates"), function (file, i) {
  return file.match(MIGRATE_PATTERN);
}).sort();

console.log(name, migrates);
