require 'thinking_sphinx/deltas/default_delta'
require 'thinking_sphinx/deltas/delayed_delta'
require 'thinking_sphinx/deltas/datetime_delta'

module ThinkingSphinx
  module Deltas
    def self.parse(index, options)
      case options.delete(:delta)
      when TrueClass, :default
        DefaultDelta.new index, options
      when :delayed
        DelayedDelta.new index, options
      when :datetime
        DatetimeDelta.new index, options
      when FalseClass, nil
        nil
      else
        raise "Unknown delta type"
      end
    end
  end
end
