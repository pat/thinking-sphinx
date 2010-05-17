puts "LOADING TS/thinking_sphinx/railtie"

require 'thinking_sphinx'
require 'rails'

module ThinkingSphinx
  class Railtie < Rails::Railtie

    initializer "thinking_sphinx.active_record" do
      ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord) if defined?(ActiveRecord)
    end

    initializer "thinking_sphinx.set_app_root" do |app|
      ThinkingSphinx::Configuration.instance.reset # Rails has setup app now
    end

    config.to_prepare do
      I18n.backend.reload!
      I18n.backend.available_locales
    end

    rake_tasks do
      load File.expand_path('../tasks.rb', __FILE__)
    end
  end
end
