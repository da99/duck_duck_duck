
var _  = require('underscore')
, path = require('path')
, fs = require('fs')
, River = require('da_river').River
, Topogo = require('topogo').Topogo
;

var schema_table    = process.env.MIGRATE_TABLE || '_schema';
var MIGRATE_PATTERN = /^\d+\-/;
var name            = path.basename(process.cwd());
var migrates        = _.select(fs.readdirSync("migrates"), function (file, i) {
  return file.match(MIGRATE_PATTERN);
}).sort();


River.new(null)
.job(function (j) {
  Topogo.run('CREATE TABLE IF NOT EXISTS ' + schema_table + ' (' +
             ' name varchar(255) NOT NULL UNIQUE ,   ' +
             ' version smallint NOT NULL DEFAULT 0 ' +
             ')', [], j);
})
// .job(function (j, last) {
  // console.log(name, migrates);
  // console.log(last, last[0]);
  // j.finish();
// })
.run(function () {
  Topogo.close();
});

