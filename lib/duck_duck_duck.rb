
require "sequel"

class Duck_Duck_Duck

  DB           = Sequel.connect(ENV['DATABASE_URL'])
  SCHEMA_TABLE = ENV['SCHEMA_TABLE'] || '_schema'

  class << self

    def canonical_name name
      name.upcase
    end # === def canonical_name

    def dev_only
      fail "Not allowed on a dev machine." if ENV['IS_DEV']
    end

    def create *args
      new(*args).create
    end

    def migrate_schema
      DB << <<-EOF
        CREATE TABLE IF NOT EXISTS #{SCHEMA_TABLE} (
          name              varchar(255) NOT NULL PRIMARY KEY,
          display_name      varchar(255) NOT NULL UNIQUE,
          version           smallint     NOT NULL DEFAULT 0
        )
      EOF
    end

    def read_file f
      raw = File.read(f).split(/\s*--\s+(UP|DOWN):?\s*/).
      inject([:UP, { :UP => [], :DOWN => [] }]) do |memo, val|
        dir  = memo.first
        meta = memo.last

        case val
        when 'UP', :UP, :DOWN, 'DOWN'
          dir = val.to_sym
        when ''
          # do nothing
        else
          meta[dir] << val
        end

        [dir, meta]
      end
      meta = raw.last
      {:UP=>meta[:UP].join("\n"), :DOWN=>meta[:DOWN].join("\n")}
    end

    %w{reset up down}.each { |meth|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{meth} name = nil
          migrate_schema
          puts "=== #{meth}: \#{name}"
          new(name).#{meth}
        end
      EOF
    }

  end # === class self ===

  # ===============================================
  # Instance methods:
  # ===============================================

  attr_reader :name, :display_name, :action, :sub_action

  def initialize *args
    @display_name, @action, @sub_action = args
    if !@display_name
      fail ArgumentError, "Name required."
    end

    @name = Duck_Duck_Duck.canonical_name(display_name)
    @files = Dir.glob("#{display_name}/migrates/*.sql")
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
      ds = DB["INSERT INTO #{SCHEMA_TABLE} (name, display_name, version) VALUES (?, ?, ?)", name, display_name, 0]
      ds.insert
      rec = {:version=>0}
    end

    if rec[:version] < 0
      puts "#{display_name} has an invalid version: #{rec[:version]}\n"
      exit 1
    end

    files = @files.sort.map { |f|
      ver = file_to_ver(f)
      if ver > rec[:version]
        [ ver, Duck_Duck_Duck.read_file(f)[:UP] ]
      end
    }.compact

    files.each { |pair|
      ver = pair.first
      sql = pair[1]
      DB << sql
      DB[" UPDATE #{SCHEMA_TABLE.inspect} SET version = ? WHERE name = ? ", ver, name].update
      puts "#{display_name} schema is now : #{ver}"
    }

    if files.empty?
      puts "#{display_name} is already the latest: #{rec[:version]}"
    end
  end # === def up

  def down
    rec = DB.fetch("SELECT version FROM #{SCHEMA_TABLE} WHERE name = :name",  :name=>name).all.first

    if !rec
      ds = DB["INSERT INTO #{SCHEMA_TABLE} (name, display_name, version) VALUES (?, ?, ?)", name, display_name, 0]
      ds.insert
      rec = {:version=>0}
    end

    if rec[:version] == 0
      puts "#{display_name} is already the latest: #{rec[:version]}\n"
      exit 0
    end

    if rec[:version] < 0
      puts "#{display_name} is at invalid version: #{rec[:version]}\n"
      exit 1
    end

    files = @files.sort.reverse.map { |f|
      ver = file_to_ver(f)
      next unless ver <= rec[:version]
      [ ver, Duck_Duck_Duck.read_file(f)[:DOWN] ]
    }.compact

    if files.empty?
      puts "#{display_name} is already the latest: #{rec[:version]}\n"
    end

    new_ver = nil

    files.each_with_index { |pair, i|
      prev_pair = files[i+1] || [0, nil]
      ver = prev_pair.first.to_i
      sql = pair[1]
      DB << sql
      DB[" UPDATE #{SCHEMA_TABLE} SET version = ? WHERE name = ? ", ver, name].update
      puts "#{display_name} schema is now : #{ver}"
    }

  end # === def down

  def create
    `mkdir -p #{display_name}/migrates`

    files = Dir.glob("#{display_name}/migrates/*.sql").grep(/\/\d+\-/).sort

    size = 3
    next_ver = begin
                 (files.last || '')[/\/(\d+)[^\/]+\z/]
                 v = if $1
                       size = $1.size
                       $1 
                      else
                        '0'
                      end
                 "%0#{size}d" % (v.to_i + 1)
               end

    new_file = "#{display_name}/migrates/#{next_ver}-#{[action, sub_action].compact.join('-')}.sql"
    File.open(new_file, 'a') do |f|
      f.puts "\n\n\n\n-- DOWN\n\n\n\n"
    end

    puts new_file
  end # === def create


end # === class Duck_Duck_Duck ===
