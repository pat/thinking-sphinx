# frozen_string_literal: true

require 'thinking_sphinx'

ActiveSupport.on_load :active_record do
  require 'thinking_sphinx/active_record'
end
