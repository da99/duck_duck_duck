

describe 'Before first migrate:' do

  it 'creates schema table' do
    get('SELECT * FROM _test_schema').
    size.should > 0
  end

  it 'creates rows with: name, version' do
    get('SELECT * FROM _test_schema').
      first.keys.should == %w{ name version }
  end

end # === describe Before first migrate

__END__
describe( 'Migrate up:', function () {

  does( 'updates version to latest migrate', function (done) {
    River.new()

    .job(function (j) {
      Topogo.run('SELECT * FROM _test_schema', [], j);
    })

    .job(function (j, last) {
      assert(last[0].version, 3);
      done();
    })

    .run();
  });

  it( 'migrates files higher, but not equal, of current version', function () {
    var contents = fs.readFileSync('/tmp/duck_up').toString().trim();
    assert.equal(contents, "+1+2+3+4+5+6");
  });

}); // === end desc

describe( 'Migrate down:', function () {

  var contents = null;

  before(function () {
    contents = fs.readFileSync('/tmp/duck_down').toString().trim();
  });

  it( 'runs migrates in reverse order', function () {
    assert.equal(contents, "+2+4+6-6-4-2");
  });

  it( 'does not run down migrates from later versions', function () {
    // This tests is the same as "runs migrates in reverse order"
    assert.equal(contents, "+2+4+6-6-4-2");
  });

  does( 'update version to one less than earlier version', function (done) {
    River.new(null)
    .job(function (j) {
      Topogo.run('SELECT * FROM _test_schema', [], j);
    })
    .job(function (j, last) {
      var pm = _.find(last, function (rec) {
        return rec.name === 'praying_mantis';
      });
      assert.equal(pm.version, 0);
      done();
    })
    .run();
  });

}); // === end desc


describe( 'create ...', function () {

  it( 'create a file', function () {
    var contents = fs.readFileSync("tests/laughing_octopus/migrates/001-one.js").toString();
    assert.equal(contents.indexOf('var ') > -1, true);
  });

  it( 'creates file in successive order', function () {
    var contents = fs.readFileSync("tests/laughing_octopus/migrates/002-two.js").toString();
    assert.equal(contents.indexOf('var ') > -1, true);
    var contents = fs.readFileSync("tests/laughing_octopus/migrates/003-three.js").toString();
    assert.equal(contents.indexOf('var ') > -1, true);
  });

}); // === end desc



describe( 'drop_it', function () {

  it( 'migrates down', function () {
    var contents = fs.readFileSync("/tmp/duck_drop_it").toString();
    assert.deepEqual(contents, "drop_it");
  });

  does( 'removes entry from schema', function (done) {
    applets(function (list) {
      assert.deepEqual(list.liquid, undefined);
      done();
    });
  });

}); // === end desc


describe( 'list', function () {

  it( 'outputs schema table on each line: VER_NUM NAME', function () {
    var contents = fs.readFileSync("/tmp/duck_list").toString().split("\n");
    assert.deepEqual(!!contents[0].match(/\d user/), true);
    assert.deepEqual(!!contents[1].match(/\d raven_sword/), true);
  });
}); // === end desc
