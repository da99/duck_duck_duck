
require "sequel"
class Duck_Duck_Duck

  class << self

    def create name, action, sub_sction
      `mkdir -p Server/#{name}/migrates`

      files = Dir.glob("Server/#{name}/migrates/*.sql").sort

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

      new_file = "Server/#{name}/migrates/#{ver_str}-#{sub_str.join('-')}.sql"
      File.open(new_file, 'a') do |f|
        f.puts "\n\n\n\n-- DOWN\n\n\n\n"
      end

      puts new_file
    end # === def create

    def up
      rec = DB.fetch("SELECT version FROM _schema WHERE name = :name",  :name=>NAME).all.first

      if !rec
        ds = DB["INSERT INTO _schema (name, version) VALUES (?, ?)", NAME, 0]
        ds.insert
        rec = {:version=>0}
      end

      if rec[:version] < 0
        puts "#{NAME} is at invalid version: #{rec[:version]}\n"
        exit 1
      end

      files = FILES.sort.map { |f|
        ver = file_to_ver(f)
        if ver > rec[:version]
          [ ver, File.read(f).split('-- DOWN').first ]
        end
      }.compact

      files.each { |pair|
        ver = pair.first
        sql = pair[1]
        DB << sql
        DB[" UPDATE _schema SET version = ? WHERE name = ? ", ver, NAME].update
        puts "#{NAME} schema is now : #{ver}"
      }

      if files.empty?
        puts "#{NAME} is already the latest: #{rec[:version]}"
      end
    end # === def up

    def migrate_schema
      DB = Sequel.connect(ENV['DATABASE_URL'])

      DB << %!
      CREATE TABLE IF NOT EXISTS _schema (
        name      varchar(255) NOT NULL PRIMARY KEY ,
        version   smallint     NOT NULL DEFAULT 0
      )
      !

      NAME = ARGV[0]
      if !NAME
        puts "Name required."
        exit 1
      end

      def file_to_ver str
        str.split('/').pop.split('-').first.to_i
      end

      FILES = Dir.glob("Server/#{NAME}/migrates/*.sql")
    end # === def migrate_schema

    def down
      rec = DB.fetch("SELECT version FROM _schema WHERE name = :name",  :name=>NAME).all.first

      if !rec
        ds = DB["INSERT INTO _schema (name, version) VALUES (?, ?)", NAME, 0]
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

      files = FILES.sort.reverse.map { |f|
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
        DB[" UPDATE _schema SET version = ? WHERE name = ? ", ver, NAME].update
        puts "#{NAME} schema is now : #{ver}"
      }

    end # === def down

  end # === class self ===

  def initialize
  end

end # === class Duck_Duck_Duck ===
