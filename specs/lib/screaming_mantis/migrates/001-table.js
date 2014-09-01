
var table = "";
var m     = module.exports = {};

m.migrate = function (dir, r) {

  if (dir === 'down') {

    r.drop("THIS_TABLE");

  } else {

    var sql = 'CREATE TABLE IF NOT EXISTS "THIS_TABLE" ( \
    name smallint PRIMARY KEY \
    );';
    r.create(sql);

  }
};
