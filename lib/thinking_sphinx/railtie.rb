class ThinkingSphinx::Railtie < Rails::Railtie
  ActiveSupport.on_load :active_record do
    include ThinkingSphinx::ActiveRecord::Base
  end

  rake_tasks do
    load File.expand_path('../tasks.rb', __FILE__)
  end
end

# Add 'app/indices' path to Rails Engines
module ThinkingSphinx::EnginePaths
  extend ActiveSupport::Concern

  included do
    initializer :add_indices_path do
      paths.add "app/indices"
    end
  end
end

Rails::Engine.send :include, ThinkingSphinx::EnginePaths
