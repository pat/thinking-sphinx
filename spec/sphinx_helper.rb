require 'active_record'
require 'active_record/connection_adapters/mysql_adapter'
begin
  require 'active_record/connection_adapters/postgresql_adapter'
rescue LoadError
  # No postgres?  no prob...
end
require 'yaml'

class SphinxHelper
  attr_accessor :host, :username, :password
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
    end
    
    @path = File.expand_path(File.dirname(__FILE__))
  end
  
  def setup_mysql
    ActiveRecord::Base.establish_connection(
      :adapter  => 'mysql',
      :database => 'thinking_sphinx',
      :username => @username,
      :password => @password,
      :host     => @host
    )
    # ActiveRecord::Base.logger = nil
    
    structure = File.open("spec/fixtures/structure.sql") { |f| f.read.chomp }
    structure.split(';').each { |table|
      ActiveRecord::Base.connection.execute table
    }
    
    File.open("spec/fixtures/data.sql") { |f|
      while line = f.gets
        ActiveRecord::Base.connection.execute line
      end
    }
  end
  
  def reset
    setup_mysql
  end
end
