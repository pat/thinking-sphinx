require 'thinking_sphinx'
require 'action_controller/dispatcher'

ActionController::Dispatcher.to_prepare :thinking_sphinx do
  ThinkingSphinx::Configuration.instance.load_models
end
