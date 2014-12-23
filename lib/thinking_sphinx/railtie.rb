class ThinkingSphinx::Railtie < Rails::Railtie
  initializer 'thinking_sphinx.initialisation' do
    if defined?(ActiveRecord::Base)
      ActiveRecord::Base.send :include, ThinkingSphinx::ActiveRecord::Base
    end
  end

  rake_tasks do
    load File.expand_path('../tasks.rb', __FILE__)
  end
end
