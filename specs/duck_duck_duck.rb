
require 'sequel'
schema = ENV['SCHEMA_TABLE'] = '_test_schema'
DB = Sequel.connect ENV['DATABASE_URL']
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

  before { reset }

  it( 'updates version to latest migration' ) do
    `duck_duck_duck up 0010_model`
    get('SELECT * FROM _test_schema').
      first[:version].should == versions('0010_model').last
  end

  it 'does not run migrations from previous versions' do
    `duck_duck_duck migrate_schema`
    DB << File.read("0010_model/migrates/0010-table.sql").split('-- DOWN').first
    DB << "INSERT INTO #{schema.inspect} VALUES ('0010_model', '20');"
    `duck_duck_duck up 0010_model`
    get('SELECT * FROM "0010_model"', :title).
      should == ['record 30', 'record 40', 'record 50']
  end

end # === end desc

describe 'Migrate down:' do

  it 'leaves version to 0' do
    `duck_duck_duck up 0010_model`
    `duck_duck_duck down 0010_model`
    get('SELECT * FROM _test_schema WHERE name = "0010_model"', :version).last.
      should == 0
  end

  it 'runs migrates in reverse order' do
    `duck_duck_duck up 0020_model`
    `duck_duck_duck down 0020_model`
    get('SELECT * FROM 0020_model', :title).
      should == ['a']
  end

  it 'does not run down migrates from later versions' do
    `duck_duck_duck migrate_schema`
    DB << "UPDATE #{schema} SET version = '3' WHERE name = '0020_model';"
    `duck_duck_duck down 0020_model`
    get('SELECT * FROM 0020_model', :title).
      should == ['a']
  end

end # === end desc


