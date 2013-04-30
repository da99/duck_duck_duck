

var _  = require('underscore')
, path = require('path')
, fs = require('fs')
, River = require('da_river').River
, Topogo = require('topogo').Topogo
;


River.new(null)
.job(function (j) {
  Topogo.run('DROP TABLE IF EXISTS ' + (process.env.MIGRATE_TABLE || '_test_schema')+ ';', [], j);
})
.run(function () {
  Topogo.close();
});
