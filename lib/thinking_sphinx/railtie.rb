puts "LOADING TS/thinking_sphinx/railstie"

require 'thinking_sphinx'
require 'rails'

module ThinkingSphinx
  class Railtie < Rails::Railtie

    initializer "thinking_sphinx.active_record" do
      # require 'active_record'
      if defined? ::ActiveRecord
        # require 'after_commit'
        require 'thinking_sphinx/active_record'
        ::ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)
        # WillPaginate::Finders::ActiveRecord.enable!
      end
    end

    initializer "thinking_sphinx.action_dispatch" do
      ActionController::Dispatcher.to_prepare :thinking_sphinx do
        # Force internationalisation to be loaded.
        I18n.backend.reload!
        I18n.backend.available_locales
        
        # if Rails::VERSION::STRING.to_f > 2.2
        #   I18n.backend.reload!
        #   I18n.backend.available_locales
        # elsif Rails::VERSION::STRING.to_f > 2.1
        #   I18n.backend.load_translations(*I18n.load_path)
        # end
      end
    end
    
    initializer :thinking_sphinx do |application|
      puts application.inspect
      puts application.config.root
      #ThinkingSphinx::Configuration.new(application.config.root)
    end
  end
end
