# Database Defaults
host     = "localhost"
username = "thinking_sphinx"
password = nil

# Read in YAML file
if File.exist?("features/fixtures/database.yml")
  config    = YAML.load open("features/fixtures/database.yml")
  host      = config["host"]     || host
  username  = config["username"] || username
  password  = config["password"] || password
end

# Set up Connection
ActiveRecord::Base.establish_connection(
  :adapter  => 'mysql',
  :database => 'thinking_sphinx',
  :username => username,
  :password => password,
  :host     => host
)

# Add log file
ActiveRecord::Base.logger = Logger.new open("tmp/active_record.log", "a")

# Set up Database
Dir["features/fixtures/data/*.sql"].each do |file|
  open(file) do |f|
    f.read.chomp.split(';').each do |sql|
      ActiveRecord::Base.connection.execute sql
    end
  end
end

# Load Models
Dir["features/fixtures/models/*.rb"].each do |file|
  require file.gsub(/\.rb$/, '')
end

ThinkingSphinx::Configuration.instance.build
ThinkingSphinx::Configuration.instance.controller.index
ThinkingSphinx::Configuration.instance.controller.start
