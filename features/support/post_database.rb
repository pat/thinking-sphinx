$:.unshift File.dirname(__FILE__) + '/../../lib'

require 'lib/thinking_sphinx'

ThinkingSphinx.suppress_delta_output = true

%w( tmp/config tmp/log tmp/db/sphinx/development ).each do |path|
  FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
end

Kernel.const_set :RAILS_ROOT, "#{Dir.pwd}/tmp" unless defined?(RAILS_ROOT)

at_exit do
  ThinkingSphinx::Configuration.instance.controller.stop
  sleep(1) # Ensure Sphinx has shut down completely
  FileUtils.rm_r "#{Dir.pwd}/tmp"
end

# Add log file
ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new(
  open("tmp/active_record.log", "a"),
  ActiveSupport::BufferedLogger::Severity::WARN
)

# Load Models
Dir["features/support/models/*.rb"].each do |file|
  require file.gsub(/\.rb$/, '')
end

# Set up database tables and records
Dir["features/support/db/migrations/*.rb"].each do |file|
  require file.gsub(/\.rb$/, '')
end

ThinkingSphinx::Configuration.instance.build
ThinkingSphinx::Configuration.instance.controller.index
ThinkingSphinx::Configuration.instance.controller.start
