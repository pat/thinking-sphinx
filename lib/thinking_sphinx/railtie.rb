class ThinkingSphinx::Railtie < Rails::Railtie
  ActiveSupport.on_load :active_record do
    extend ThinkingSphinx::ActiveRecord::Base
  end
end
