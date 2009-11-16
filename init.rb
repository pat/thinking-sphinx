Dir[File.join(File.dirname(__FILE__), 'vendor/*/lib')].each do |path|
  $LOAD_PATH.unshift path
end

require 'thinking_sphinx/0.9.8'

if Rails::VERSION::STRING.to_f < 2.1
  ThinkingSphinx::Configuration.instance.load_models
end

if Rails::VERSION::STRING.to_f > 1.2
  require 'action_controller/dispatcher'
  ActionController::Dispatcher.to_prepare :thinking_sphinx do
    ThinkingSphinx::Configuration.instance.load_models
  end
end