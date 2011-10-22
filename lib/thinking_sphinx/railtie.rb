class ThinkingSphinx::Railtie < Rails::Railtie
  ActiveSupport.on_load :active_record do
    include ThinkingSphinx::ActiveRecord::Base
  end

  rake_tasks do
    load File.expand_path('../tasks.rb', __FILE__)
  end
end
