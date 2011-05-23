require 'thinking_sphinx'

ThinkingSphinx::Configuration.instance

ActiveSupport.on_load :active_record do
  include ThinkingSphinx::ActiveRecord
end
