require 'active_support/dependencies'

root = File.expand_path File.join(File.dirname(__FILE__), '..')
ActiveSupport::Dependencies.autoload_paths << "#{root}/acceptance/models"
ActiveSupport::Dependencies.autoload_paths << "#{root}/acceptance/indices"

ActiveSupport.on_load :active_record do
  extend ThinkingSphinx::ActiveRecord::Base
end
