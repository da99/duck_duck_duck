
require "sequel"

class Duck_Duck_Duck

  DB           = Sequel.connect(ENV['DATABASE_URL'])
  SCHEMA_TABLE = ENV['SCHEMA_TABLE'] || '_schema'

  class << self

    def stdout *args
      args.each { |a| print "#{a}\n" }
    end

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
          version           smallint     NOT NULL DEFAULT 0
        )
      EOF
    end

    def read_file f
      raw = File.read(f).split(/\s*--\s+(UP|BOTH|DOWN):?\s*/).
      inject([:UP, {:UP=>[], :DOWN=>[]}]) do |memo, val|
        dir   = memo.first
        meta  = memo.last

        case val
        when 'UP', :UP, :DOWN, 'DOWN', 'BOTH', :BOTH
          dir = val.to_sym
        when ''
          # do nothing
        else
          case dir
          when :BOTH
            meta[:UP] << val
            meta[:DOWN] << val
          else
            meta[dir] << val
          end
        end

        [dir, meta]
      end

      meta = raw.last
      {:UP=>meta[:UP].join("\n"), :DOWN=>meta[:DOWN].join("\n")}
    end # === def read_file

    %w{reset up down}.each { |meth|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{meth} name = nil
          migrate_schema
          stdout "=== #{meth}: \#{name}"
          new(name).#{meth}
        end
      EOF
    }

  end # === class self ===

  # ===============================================
  # Instance methods:
  # ===============================================

  attr_reader :name, :action, :sub_action

  def initialize *args
    @name, @action, @sub_action = args
    if !@name
      fail ArgumentError, "Name required."
    end

    @__files = `find . -iregex ".+/#{name}/migrates/__.+\.sql"`
    .strip
    .split("\n")
    .sort

    @files = (
      `find . -iregex ".+/#{name}/migrates/.+\.sql"`
      .strip
      .split("\n")
      .grep(/\/\d+\-/)
      .sort
    )
  end

  def stdout *args
    Duck_Duck_Duck.stdout *args
  end

  def file_to_ver str
    File.basename(str)[/\A\d{1,}/].to_i
  end

  def reset
    down
    up
  end

  def init_model_in_schema
    rec = DB.fetch(
      "SELECT version FROM #{SCHEMA_TABLE} WHERE name = upper( :name )",
      :name=>name
    ).all.first

    if !rec
      dir_name = "#{name}/migrates"
      dir = `find . -iregex ".+/#{dir_name}"`.strip.split("\n")
      if dir.empty?
        fail "Directory #{dir_name} does not exist."
      end
      rec = DB.fetch(
        "INSERT INTO #{SCHEMA_TABLE} (name, version) VALUES (upper(:name), :version) RETURNING *",
        :name=>name, :version=>0
      ).all.first
    end

    {:version=>rec[:version]}
  end

  def up
    rec = init_model_in_schema

    if rec[:version] < 0
      stdout "#{name} has an invalid version: #{rec[:version]}\n"
      exit 1
    end

    files = @files.sort.map { |f|
      ver = file_to_ver(f)
      if ver > rec[:version]
        [ ver, Duck_Duck_Duck.read_file(f)[:UP] ]
      end
    }.compact

    if @__files.empty? && files.empty?
      stdout "#{name} is already the latest: #{rec[:version]}"
    end

    @__files.each { |f|
      DB << Duck_Duck_Duck.read_file(f)[:UP]
      stdout "ran file: #{f}"
    }

    files.each { |pair|
      ver = pair.first
      sql = pair[1]
      DB << sql
      DB[" UPDATE #{SCHEMA_TABLE.inspect} SET version = ? WHERE name = upper( ? ); ", ver, name].update
      stdout "#{name} schema is now : #{ver}"
    }

  end # === def up

  def down
    rec = init_model_in_schema

    if rec[:version] < 0
      stdout "#{name} is at invalid version: #{rec[:version]}\n"
      exit 1
    end

    files = if rec[:version] == 0
              []
            else
              @files.sort.reverse.map { |f|
                ver = file_to_ver(f)
                next unless ver <= rec[:version]
                [ ver, Duck_Duck_Duck.read_file(f)[:DOWN] ]
              }.compact
            end

    if @__files.empty? && files.empty?
      stdout "#{name} is already the latest: #{rec[:version]}\n"
      exit 0
    end

    new_ver = nil

    files.each_with_index { |pair, i|
      prev_pair = files[i+1] || [0, nil]
      ver = prev_pair.first.to_i
      sql = pair[1]
      DB << sql
      DB[" UPDATE #{SCHEMA_TABLE} SET version = ? WHERE name = upper( ? )", ver, name].update
      stdout "#{name} schema is now : #{ver}"
    }

    @__files.reverse.each { |f|
      DB << Duck_Duck_Duck.read_file(f)[:DOWN]
      stdout "down: #{f}"
    }

  end # === def down

  def create
    `mkdir -p #{name}/migrates`

    size = 3
    next_ver = begin
                 (@files.last || '')[/\/(\d+)[^\/]+\z/]
                 v = if $1
                       size = $1.size
                       $1
                      else
                        '0'
                      end
                 "%0#{size}d" % (v.to_i + 1)
               end

    new_file = "#{name}/migrates/#{next_ver}-#{[action, sub_action].compact.join('-')}.sql"
    File.open(new_file, 'a') do |f|
      f.print "\n\n\n\n-- DOWN\n\n\n\n"
    end

    stdout new_file
  end # === def create


end # === class Duck_Duck_Duck ===
