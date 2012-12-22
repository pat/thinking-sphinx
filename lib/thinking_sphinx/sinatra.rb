require 'thinking_sphinx'

ActiveSupport.on_load :active_record do
  include ThinkingSphinx::ActiveRecord::Base
end
