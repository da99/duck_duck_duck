
var Topogo = require("topogo").Topogo;
var River  = require("da_river").River;

var table = "";
var m     = module.exports = {};

m.migrate = function (dir, r) {

  if (dir === 'down') {

    Topogo.run('DROP TABLE IF EXISTS ' + table +  ';', [], r);

  } else {

    var sql = 'CREATE TABLE IF NOT EXISTS ' + table + " ( \
\
    );";
    Topogo.run(sql, [], r);

  }
};
