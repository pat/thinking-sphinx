require 'thinking_sphinx/0.9.8'
require 'action_controller/dispatcher'

ActionController::Dispatcher.to_prepare :thinking_sphinx do
  # Force internationalisation to be loaded.
  if Rails::VERSION::STRING.to_f > 2.2
    I18n.backend.reload!
    I18n.backend.available_locales
  elsif Rails::VERSION::STRING.to_f > 2.1
    I18n.backend.load_translations(*I18n.load_path)
  end
  
  ThinkingSphinx::Configuration.instance.load_models
end
