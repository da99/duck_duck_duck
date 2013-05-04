
var Topogo = require("topogo").Topogo;
var River  = require("da_river").River;
var fs     = require('fs');

var table = "_test_duck_liquid";
var m     = module.exports = {};

m.migrate = function (dir, r) {

  if (dir === 'down') {

    fs.writeFile('/tmp/duck_drop_it', "drop_it", function (err) {
      if (err) throw err;
      Topogo.run('DROP TABLE IF EXISTS ' + table +  ';', [], r);
    });


  } else {

    var sql = 'CREATE TABLE IF NOT EXISTS ' + table + " ( \
id serial PRIMARY KEY \
    );";
    Topogo.run(sql, [], r);

  }
};
