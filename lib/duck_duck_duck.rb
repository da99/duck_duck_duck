
require "sequel"

class Duck_Duck_Duck

  DB           = Sequel.connect(ENV['DATABASE_URL'])
  SCHEMA_TABLE = ENV['SCHEMA_TABLE'] || '_schema'

  class << self

    def dev_only
      fail "Not allowed on a dev machine." if ENV['IS_DEV']
    end

    def create *args
      new(*args).create
    end

    %w{reset up down}.each { |meth|
      eval %^
        def #{meth} name = nil
          names = name ? [name] : models
          names.each { |name|
            new(name).#{meth}
          }
        end
      ^
    }

    private # ======================================

    def models
      @models ||= Dir.glob("*/migrates").
        map { |dir| File.basename File.dirname(dir) }
    end

  end # === class self ===

  # ===============================================
  # Instance methods:
  # ===============================================

  attr_reader :name, :action, :sub_action

  def initialize *args
    @name, @action, @sub_action = args
  end

  def reset
    down
    up
  end

  def migrate_schema
    DB << <<-EOF
      CREATE TABLE IF NOT EXISTS #{SCHEMA_TABLE} (
        name      varchar(255) NOT NULL PRIMARY KEY ,
        version   smallint     NOT NULL DEFAULT 0
      )
    EOF

    def file_to_ver str
      str.split('/').pop.split('-').first.to_i
    end

    @files = Dir.glob("#{name}/migrates/*.sql")
  end # === def migrate_schema

  def up
    migrate_schema
    rec = DB.fetch("SELECT version FROM #{SCHEMA_TABLE} WHERE name = :name",  :name=>name).all.first

    if !rec
      ds = DB["INSERT INTO #{SCHEMA_TABLE} (name, version) VALUES (?, ?)", name, 0]
      ds.insert
      rec = {:version=>0}
    end

    if rec[:version] < 0
      puts "#{name} has an invalid version: #{rec[:version]}\n"
      exit 1
    end

    files = @files.sort.map { |f|
      ver = file_to_ver(f)
      if ver > rec[:version]
        [ ver, File.read(f).split('-- DOWN').first ]
      end
    }.compact

    files.each { |pair|
      ver = pair.first
      sql = pair[1]
      DB << sql
      DB[" UPDATE #{SCHEMA_TABLE} SET version = ? WHERE name = ? ", ver, name].update
      puts "#{name} schema is now : #{ver}"
    }

    if files.empty?
      puts "#{name} is already the latest: #{rec[:version]}"
    end
  end # === def up

  def down
    migrate_schema
    rec = DB.fetch("SELECT version FROM #{SCHEMA_TABLE} WHERE name = :name",  :name=>NAME).all.first

    if !rec
      ds = DB["INSERT INTO #{SCHEMA_TABLE} (name, version) VALUES (?, ?)", NAME, 0]
      ds.insert
      rec = {:version=>0}
    end

    if rec[:version] == 0
      puts "#{NAME} is already the latest: #{rec[:version]}\n"
      exit 0
    end

    if rec[:version] < 0
      puts "#{NAME} is at invalid version: #{rec[:version]}\n"
      exit 1
    end

    files = @files.sort.reverse.map { |f|
      ver = file_to_ver(f)

      if ver <= rec[:version]
        [ ver, File.read(f).split('-- DOWN').last ]
      end
    }.compact

    if files.empty?
      puts "#{NAME} is already the latest: #{rec[:version]}\n"
    end

    new_ver = nil

    files.each { |pair|
      ver = pair.first - 1
      sql = pair[1]
      DB << sql
      DB[" UPDATE #{SCHEMA_TABLE} SET version = ? WHERE name = ? ", ver, NAME].update
      puts "#{NAME} schema is now : #{ver}"
    }

  end # === def down

  def create
    `mkdir -p #{name}/migrates`

    files = Dir.glob("#{name}/migrates/*.sql").sort

    if files.empty?
      ver=1
    else
      last=files.last.split('/').last || "/0"
      ver=last.split('/').last.split('-').first.to_i + 1
    end


    if ver < 10
      ver_str = "00#{ver}"
    elsif ver < 100
      ver_str = "0#{ver}"
    else
      ver_str = "#{ver}"
    end

    sub_str=[name, action, sub_action].compact
    if sub_str.size > 2
      sub_str.shift
    end

    new_file = "#{name}/migrates/#{ver_str}-#{sub_str.join('-')}.sql"
    File.open(new_file, 'a') do |f|
      f.puts "\n\n\n\n-- DOWN\n\n\n\n"
    end

    puts new_file
  end # === def create


end # === class Duck_Duck_Duck ===
