
require 'sequel'
require 'Exit_0'

schema = ENV['SCHEMA_TABLE'] = '_test_schema'
DB     = Sequel.connect ENV['DATABASE_URL']
MODELS = Dir.glob('*/migrates').map { |dir|  File.basename File.dirname(dir) }

# === Reset tables ===========================================================
def reset
  tables = MODELS + [ENV['SCHEMA_TABLE']]
  tables.each { |t|
    DB << "DROP TABLE IF EXISTS #{t.inspect};"
  }
end

reset

# === Helpers ================================================================
def get *args
  field = args.last.is_a?(Symbol) ? args.pop : nil
  rows = DB[*args].all
  if field
    rows.map { |row| row[field] }
  else
    rows
  end
end

def versions mod
  Dir.glob("#{mod}/migrates/*").map { |file|
    file[/\/(\d{4})[^\/]+\.sql\z/] && $1.to_i
  }.sort
end

# === Specs ==================================================================

describe :initialize do

  it "fails if no name is given" do
    should.raise(ArgumentError) {
      Duck_Duck_Duck.new
    }.message.should.match /Name required/
  end # === it fails if no name is given

end # === describe :initialize

describe "read_file" do

  it "returns: {:UP=>STRING, :DOWN=>STRING}" do
    file = "/tmp/ddd_up_down.sql"
    File.write(file, ["-- DOWN", "2", "-- UP", "1", "-- DOWN", "2", "-- UP", "1"].join("\n"))
    Duck_Duck_Duck.read_file(file).
      should == {:UP=>"1\n1", :DOWN=>"2\n2"}
  end # === it

  it "ignores colons: UP, UP:, DOWN, DOWN:" do
    file = "/tmp/ddd_up_down.sql"
    File.write(file, ["-- DOWN:", "2", "-- UP:", "1", "-- DOWN:", "2", "-- UP:", "1"].join("\n"))
    Duck_Duck_Duck.read_file(file).
      should == {:UP=>"1\n1", :DOWN=>"2\n2"}
  end # === it

  it "ignores trailing whitespace: -- UP   \n" do
    file = "/tmp/ddd_up_down.sql"
    File.write(file, ["-- DOWN:   ", "2", "-- UP   ", "1", "-- DOWN   ", "2", "-- UP:   ", "1"].join("\n"))
    Duck_Duck_Duck.read_file(file).
      should == {:UP=>"1\n1", :DOWN=>"2\n2"}
  end # === it

end # === describe "read_file"

describe "create" do

  before {
    tmp_dir = '/tmp/ddd_ver'
    Exit_0("rm -fr #{tmp_dir}")
    Exit_0("mkdir -p #{tmp_dir}")
    @dir = tmp_dir
  }

  it "names the file in successive file versions: 000-....sql" do
    Dir.chdir(@dir) {
      Exit_0("duck_duck_duck create MOD table_1")
      Exit_0("duck_duck_duck create MOD table_2")

      Exit_0("touch MOD/migrates/005-skip_zero.sql")
      Exit_0("duck_duck_duck create MOD table_3")

      Exit_0("touch MOD/migrates/009-skip_zero.sql")
      Exit_0("duck_duck_duck create MOD table_100")

      File.should.exists('MOD/migrates/001-table_1.sql')
      File.should.exists('MOD/migrates/002-table_2.sql')
      File.should.exists('MOD/migrates/006-table_3.sql')
      File.should.exists('MOD/migrates/010-table_100.sql')
    }
  end

end # === describe create

describe 'up model' do

  before { reset }

  it( 'updates version to latest migration' ) do
    Exit_0("duck_duck_duck up 0010_model")
    get('SELECT * FROM _test_schema').
      first[:version].should == versions('0010_model').last
  end

  it 'does not run migrations from previous versions' do
    Exit_0("duck_duck_duck migrate_schema")
    DB << File.read("0010_model/migrates/0010-table.sql").split('-- DOWN').first
    DB << "INSERT INTO #{schema.inspect} VALUES ('0010_model', '0010_MODEL', '20');"
    Exit_0("duck_duck_duck up 0010_model")
    get('SELECT * FROM "0010_model"', :title).
      should == ['record 30', 'record 40', 'record 50']
  end

end # === describe up model

describe 'down model' do

  before { reset }

  it 'leaves version to 0' do
    Exit_0("duck_duck_duck up 0010_model")
    Exit_0("duck_duck_duck down 0010_model")
    get(%^SELECT * FROM #{schema.inspect} WHERE name = '0010_model'^, :version).last.
      should == 0
  end

  it 'runs migrates in reverse order' do
    Exit_0("duck_duck_duck up 0020_model")
    Exit_0("duck_duck_duck down 0020_model")
    get('SELECT * FROM "0020_model"', :title).
      should == ['record 20', 'record 30', 'DROP record 30', 'DROP record 20', 'DROP 0020_model']
  end

  it 'does not run down migrates from later versions' do
    Exit_0("duck_duck_duck migrate_schema")
    DB << File.read("0020_model/migrates/0010-table.sql").split('-- DOWN').first
    DB << "INSERT INTO #{schema.inspect} VALUES ('0020_model', '0020_MODEL', '20');"
    DB << "UPDATE #{schema} SET version = '20' WHERE name = '0020_model';"
    Exit_0("duck_duck_duck down 0020_model")
    get('SELECT title FROM "0020_model"', :title).
      should == ['DROP record 20', 'DROP 0020_model']
  end

end # === describe down model

describe '-- UP/-- DOWN model' do

  before { reset }

  it "runs UPs in proper order" do
    Exit_0("duck_duck_duck up 0030_model")
    get(%^SELECT title FROM "0030_model"^).
      should == [
        {:title=>"record 1-1: 0030_model"},
        {:title=>"record 2-1: 0030_model"},
        {:title=>"record 2-2: 0030_model"},
    ]
  end # === it

end # === describe '-- UP/-- DOWN model'


