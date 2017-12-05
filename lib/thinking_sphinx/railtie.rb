# frozen_string_literal: true

class ThinkingSphinx::Railtie < Rails::Railtie
  initializer 'thinking_sphinx.initialisation' do
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.send :include, ThinkingSphinx::ActiveRecord::Base
    end
  end

  rake_tasks do
    load File.expand_path('../tasks.rb', __FILE__)
  end
end
