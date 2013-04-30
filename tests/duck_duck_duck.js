
var _    = require('underscore')
, Topogo = require('topogo').Topogo
, River = require('da_river').River
, assert = require('assert')
;


describe( 'schema table', function () {
  it( 'gets created', function (done) {
    River.new(null)
    .job(function (j) {
      Topogo.run('SELECT * FROM _test_schema', [], j);
    })
    .job(function (j, last) {
      assert.equal(last.length > 0, true);
      done();
    })
    .run();
  });

  it( 'creates rows with: name, version', function (done) {
    River.new(null)
    .job(function (j) {
      Topogo.run('SELECT * FROM _test_schema', [], j);
    })
    .job(function (j, last) {
      assert.deepEqual(_.keys(last[0]), ['name', 'version']);
      done();
    })
    .run();
  });
}); // === end desc
