require 'active_record'
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
    
    if ActiveRecord::Base.connection.tables.include?("people")
      ActiveRecord::Base.connection.drop_table "people"
    end
    
    structure = File.open("spec/fixtures/structure.sql") { |f| f.read }
    ActiveRecord::Base.connection.execute structure
    
    File.open("spec/fixtures/data.sql") { |f|
      count = 0
      while (line = f.gets) && (count < 1000)
        ActiveRecord::Base.connection.execute line
        count += 1
      end
    }
  end
  
  def reset
    setup_mysql
  end
end