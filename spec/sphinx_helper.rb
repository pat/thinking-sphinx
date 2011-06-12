require 'active_record'
prefix = defined?(JRUBY_VERSION) ? "jdbc" : ""
require "active_record/connection_adapters/#{prefix}mysql_adapter"
require "active_record/connection_adapters/mysql2_adapter"

begin
  require "active_record/connection_adapters/#{prefix}postgresql_adapter"
rescue LoadError
  # No postgres?  no prob...
end
require 'yaml'

class SphinxHelper
  attr_accessor :host, :username, :password, :socket
  attr_reader   :path

  def initialize
    @host     = "localhost"
    @username = "thinking_sphinx"
    @password = ""

    if File.exist?("spec/fixtures/database.yml")
      config    = YAML.load(File.open("spec/fixtures/database.yml"))
      @host     = config["host"]
      @username = config["username"]
      @password = config["password"]
      @socket   = config["socket"]
    end

    @path = File.expand_path(File.dirname(__FILE__))
  end

  def mysql_adapter
    defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql'
  end

  def setup_mysql
    ActiveRecord::Base.establish_connection(
      :adapter  => mysql_adapter,
      :database => 'thinking_sphinx',
      :username => @username,
      :password => @password,
      :host     => @host,
      :socket   => @socket
    )
    ActiveRecord::Base.logger = Logger.new(File.open("tmp/activerecord.log", "a"))

    structure = File.open("spec/fixtures/structure.sql") { |f| f.read.chomp }
    structure.split(';').each { |table|
      ActiveRecord::Base.connection.execute table
    }

    File.open("spec/fixtures/data.sql") { |f|
      while line = f.gets
        ActiveRecord::Base.connection.execute line unless line.blank?
      end
    }
  end

  def setup_sphinx
    @configuration = ThinkingSphinx::Configuration.instance.reset
    File.open("spec/fixtures/sphinx/database.yml", "w") do |file|
      YAML.dump({@configuration.environment => {
        :adapter  => mysql_adapter,
        :host     => @host,
        :database => "thinking_sphinx",
        :username => @username,
        :password => @password
      }}, file)
    end
    FileUtils.mkdir_p(@configuration.searchd_file_path)

    @configuration.database_yml_file = "spec/fixtures/sphinx/database.yml"
    @configuration.build

    index
  end

  def reset
    setup_mysql
  end

end