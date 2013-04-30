
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

var direction = (process.argv.indexOf('down') > 0) ? 'down' : 'up';

River.new(null)
.job(function (j) {
  Topogo.run('CREATE TABLE IF NOT EXISTS ' + schema_table + ' (' +
             ' name varchar(255) NOT NULL UNIQUE ,   ' +
             ' version smallint NOT NULL DEFAULT 0 ' +
             ')', [], j);
})
.job(function (j) {
  Topogo.run('SELECT * FROM ' + schema_table + ' WHERE name = $1 ;', [name], j);
})
.job(function (j, last) {
  j.finish(last[0]);
})
.job(function (j, last) {
  if (last)
    j.finish(last);
  else {
    River.new(null)
    .job(function (j_create) {
      Topogo.new(schema_table)
      .create({name: name}, j_create);
    })
    .run(function (j_create, last) {
      j.finish(last.version);
    });
  }
})
.job(function (j, last_max) {
  var max = 0;
  var r = River.new(null);
  var has_migrates = false;

  _.each(migrates, function (f) {

    // Should it run?
    max = parseInt(f, 10);
    if (direction === 'up' && last_max >= max)
      return;
    if (direction === 'down' && last_max <= max)
      return;

    has_migrates = true;

    // Yes? Then run it..
    var m = require(process.cwd() + '/migrates/' + f);

    r.job(function (j) {
      m.migrate(direction, j);
    });

    r.job(function (j) {
      var t = Topogo.new(schema_table);
      t.update({name: name}, {version: max}, j);
    });

  });

  if (has_migrates) {
    r.run(function () {
      j.finish();
    });
  } else {
    j.finish();
  }

})
.run(function () {
  Topogo.close();
});

