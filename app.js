
var _  = require('underscore')
, path = require('path')
, fs = require('fs')
, exec = require('child_process').exec
, River = require('da_river').River
, Topogo = require('topogo').Topogo
;

var schema_table    = process.env.MIGRATE_TABLE || '_schema';
var MIGRATE_PATTERN = /^\d+\-/;
var name            = path.basename(process.cwd());
var template        = "\
var Topogo = require(\"topogo\").Topogo;\n\
\n\
var m = module.exports = {};\n\
\n\
m.migrate = function (dir, r) {\n\
\n\
  if (dir === 'down') {\n\
\n\
    var sql = '';\n\
    Topogo.run(sql, [], r);\n\
\n\
  } else {\n\
\n\
    var sql = '';\n\
    Topogo.run(sql, [], r);\n\
\n\
  }\n\
\n\
};";

// From: stackoverflow.com/questions/1267283/how-can-i-create-a-zerofilled-value-using-javascript
function pad_it(n, p, c) {
    var pad_char = typeof c !== 'undefined' ? c : '0';
    var pad = new Array(1 + p).join(pad_char);
    return (pad + n).slice(-pad.length);
}

function read_migrates() {
  var folder = 'migrates';
  return (fs.existsSync(folder)) ? _.select(fs.readdirSync(folder), function (file, i) {
    return file.match(MIGRATE_PATTERN);
  }) : []
}

if (process.argv.indexOf('create') > 1) {

  var file_name = _.last(process.argv);
  exec("mkdir -p migrates", function (err, data) {
    if (err) throw err;

    var max = _.map(read_migrates(), function (f_name, i) {
      return parseInt(f_name, 10);
    }).sort().pop() || 0;

    var final_file_name = pad_it(max + 1, 3) + "-" + file_name + '.js';

    process.chdir('migrates')
    fs.writeFile(final_file_name, template, function () {
    });
  });

} else {
  var migrates  = read_migrates();
  var direction = (process.argv.indexOf('down') > 0) ? 'down' : 'up';


  if (direction === 'down')
    migrates.sort().reverse();
  else
    migrates.sort();

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
      j.finish(last.version);
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
      if (direction === 'down' && last_max < max)
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


}



