
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

    def migrate_schema
      DB << <<-EOF
        CREATE TABLE IF NOT EXISTS #{SCHEMA_TABLE} (
          name      varchar(255) NOT NULL PRIMARY KEY ,
          version   smallint     NOT NULL DEFAULT 0
        )
      EOF
    end

    %w{reset up down}.each { |meth|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{meth} name = nil
          migrate_schema
          names = name ? [name] : models
          names.each { |name|
            new(name).#{meth}
          }
        end
      EOF
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
    if !@name
      fail ArguementError, "Name required."
    end
    @files = Dir.glob("#{name}/migrates/*.sql")
  end

  def file_to_ver str
    File.basename(str)[/\A\d{1,}/].to_i
  end

  def reset
    down
    up
  end

  def up
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
      DB[" UPDATE #{SCHEMA_TABLE.inspect} SET version = ? WHERE name = ? ", ver, name].update
      puts "#{name} schema is now : #{ver}"
    }

    if files.empty?
      puts "#{name} is already the latest: #{rec[:version]}"
    end
  end # === def up

  def down
    rec = DB.fetch("SELECT version FROM #{SCHEMA_TABLE} WHERE name = :name",  :name=>name).all.first

    if !rec
      ds = DB["INSERT INTO #{SCHEMA_TABLE} (name, version) VALUES (?, ?)", name, 0]
      ds.insert
      rec = {:version=>0}
    end

    if rec[:version] == 0
      puts "#{name} is already the latest: #{rec[:version]}\n"
      exit 0
    end

    if rec[:version] < 0
      puts "#{name} is at invalid version: #{rec[:version]}\n"
      exit 1
    end

    files = @files.sort.reverse.map { |f|
      ver = file_to_ver(f)
      next unless ver <= rec[:version]
      [ ver, File.read(f).split('-- DOWN').last ]
    }.compact

    if files.empty?
      puts "#{name} is already the latest: #{rec[:version]}\n"
    end

    new_ver = nil

    files.each_with_index { |pair, i|
      prev_pair = files[i+1] || [0, nil]
      ver = prev_pair.first.to_i
      sql = pair[1]
      DB << sql
      DB[" UPDATE #{SCHEMA_TABLE} SET version = ? WHERE name = ? ", ver, name].update
      puts "#{name} schema is now : #{ver}"
    }

  end # === def down

  def create
    `mkdir -p #{name}/migrates`

    files = Dir.glob("#{name}/migrates/*.sql").grep(/\/\d{4}\-/).sort

    next_ver = begin
                 (files.last || '')[/\/(\d{4})[^\/]+\z/]
                 v = ($1 ? $1 : '0')
                 '%04d' % (v.to_i + (10 - v[/\d\z/].to_i))
               end

    new_file = "#{name}/migrates/#{next_ver}-#{[action, sub_action].compact.join('-')}.sql"
    File.open(new_file, 'a') do |f|
      f.puts "\n\n\n\n-- DOWN\n\n\n\n"
    end

    puts new_file
  end # === def create


end # === class Duck_Duck_Duck ===
