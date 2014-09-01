
require 'sequel'
ENV['SCHEMA_TABLE'] = '_test_schema'
DB = Sequel.connect ENV['DATABASE_URL']

# === Reset tables ===========================================================
def erase_tables
  models = Dir.glob('*/migrates').map { |dir|  File.basename File.dirname(dir) }
  tables = models.dup
  tables << ENV['SCHEMA_TABLE']
  tables.each { |t|
    DB << "DROP TABLE IF EXISTS #{t.inspect};"
  }
end

erase_tables
# at_exit { erase_tables }

# === Helpers ================================================================
def get *args
  DB[*args].all
end

def versions mod
  Dir.glob("#{mod}/migrates/*").map { |file|
    file[/\/(\d{4})[^\/]+\.sql$/] && $1.to_i
  }.sort
end

# === Specs ==================================================================

describe "create" do

  before {
    tmp_dir = '/tmp/ddd_ver'
    `rm -fr #{tmp_dir}`
    `mkdir -p #{tmp_dir}`
    @dir = tmp_dir
  }

  it "names the file in successive file versions: 0000-....sql" do
    Dir.chdir(@dir) {
      `duck_duck_duck create MOD table_1`
      `duck_duck_duck create MOD table_2`

      `touch MOD/migrates/0022-skip_zero.sql`
      `duck_duck_duck create MOD table_3`

      `touch MOD/migrates/0091-skip_zero.sql`
      `duck_duck_duck create MOD table_100`

      File.should.exists('MOD/migrates/0010-table_1.sql')
      File.should.exists('MOD/migrates/0020-table_2.sql')
      File.should.exists('MOD/migrates/0030-table_3.sql')
      File.should.exists('MOD/migrates/0100-table_100.sql')
    }
  end

end # === describe create

describe 'Migrate up:' do

  it( 'updates version to latest migrate' ) do
    `duck_duck_duck up 0010_model`
    get('SELECT * FROM _test_schema').
      first[:version].should == versions('0010_model').last
  end

end # === end desc

__END__
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
