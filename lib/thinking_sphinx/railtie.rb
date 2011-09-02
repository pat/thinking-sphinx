require 'thinking_sphinx'
require 'rails'

module ThinkingSphinx
  class Railtie < Rails::Railtie

    initializer 'thinking_sphinx.sphinx' do
      ThinkingSphinx::AutoVersion.detect
    end

    initializer "thinking_sphinx.active_record" do
      ActiveSupport.on_load :active_record do
        include ThinkingSphinx::ActiveRecord
      end
    end

    initializer "thinking_sphinx.action_controller" do
      ActiveSupport.on_load :action_controller do
        require 'thinking_sphinx/action_controller'
        include ThinkingSphinx::ActionController
      end
    end

    initializer "thinking_sphinx.set_app_root" do |app|
      ThinkingSphinx::Configuration.instance.reset # Rails has setup app now
    end

    config.to_prepare do
      # ActiveRecord::Base.to_crc32s is dependant on the subclasses being loaded
      # consistently. When the environment is reset, subclasses/descendants will
      # be lost but our context will not reload them for us.
      #
      # We reset the context which causes the subclasses/descendants to be
      # reloaded next time the context is called.
      #
      ThinkingSphinx.reset_context!
    end

    rake_tasks do
      load File.expand_path('../tasks.rb', __FILE__)
    end
  end
end
