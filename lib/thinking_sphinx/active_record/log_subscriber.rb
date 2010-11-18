require 'active_support/log_subscriber'

module ThinkingSphinx
  module ActiveRecord
    class LogSubscriber < ActiveSupport::LogSubscriber
      def self.runtime=(value)
        Thread.current['thinking_sphinx_query_runtime'] = value
      end

      def self.runtime
        Thread.current['thinking_sphinx_query_runtime'] ||= 0
      end

      def self.reset_runtime
        rt, self.runtime = runtime, 0
        rt
      end

      def initialize
        super
        @odd_or_even = false
      end

      def query(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        identifier = color('Sphinx Query (%.1fms)' % event.duration, GREEN, true)
        query = event.payload[:query]
        query = color query, nil, true if odd?

        debug "  #{identifier}  #{query}"
      end

      def message(event)
        return unless logger.debug?

        identifier = color 'Sphinx', GREEN, true
        message = event.payload[:message]
        message = color message, nil, true if odd?

        debug "  #{identifier}  #{message}"
      end

      def odd?
        @odd_or_even = !@odd_or_even
      end

      def logger
        return @logger if defined? @logger
        self.logger = ::ActiveRecord::Base.logger
      end

      def logger=(logger)
        @logger = logger
      end

      attach_to :thinking_sphinx
    end
  end
end
