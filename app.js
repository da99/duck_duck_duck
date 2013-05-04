
var _    = require('underscore')
, path   = require('path')
, fs     = require('fs')
, exec   = require('child_process').exec
, River  = require('da_river').River
, Topogo = require('topogo').Topogo
, argv   = require('optimist').argv
;

var schema_table    = process.env.SCHEMA_TABLE || '_schema';
var MIGRATE_PATTERN = /^\d+\-/;
var name            = path.basename(process.cwd());

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

if (argv._[0] === 'create') {

  var template  = fs.readFileSync(process.env.DUCK_TEMPLATE).toString();
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

} else if (_.contains(['up','down', 'drop_it'], argv._[0])) {
  var migrates  = read_migrates();
  var versions  = _.map(migrates, function (f) {
    return parseInt(f, 10);
  });

  var orig_dir  = argv._[0];
  var direction = (_.contains(['down', 'drop_it'], argv._[0])) ? 'down' : 'up';


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
    var r = River.new(null);
    var has_migrates = false;

    _.each(migrates, function (f) {
      var max = parseInt(f, 10);

      // Should it run?
      if (direction === 'up' && last_max >= max)
        return;
      if (direction === 'down' && last_max < max)
        return;

      has_migrates = true;

      // Yes? Then run it..
      var m = require(process.cwd() + '/migrates/' + f);

      r.job(function (j) {

        j.drop = function () {
          var r = River.new(j);
          _.each(_.toArray(arguments), function (t_name) {
            r.job(function (j) {
              Topogo.run("DROP TABLE IF EXISTS \"" + t_name + "\";", [], j);
            });
          });
          r.run();
        };

        j.create = function () {
          var r = River.new(j);
          _.each(_.toArray(arguments), function (sql) {
            r.job(function (j) {
              Topogo.run(sql, [], j);
            });
          });
          r.run();
        };

        m.migrate(direction, j);
      });

      r.job(function (j) {
        var t = Topogo.new(schema_table);
        if (direction === 'down') {
          max = _.find(versions.slice().reverse(), function (n) {
            return n < max;
          }) || 0;
        }
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
  .job(function (j, last) {
    if (orig_dir !== 'drop_it')
      return j.finish(last);
    Topogo.run("DELETE FROM \"" + schema_table + "\" WHERE name = $1;", [name], j);
  })
  .run(function (r, last) {
    Topogo.close();
  });


} else {
  throw new Error("Unknown argument: " + JSON.stringify(argv._));
}



