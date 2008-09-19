require 'thinking_sphinx'

ActionController::Dispatcher.to_prepare :thinking_sphinx do
  ThinkingSphinx::Configuration.new.load_models
end