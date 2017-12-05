# frozen_string_literal: true

module ThinkingSphinx::Connection
  MAXIMUM_RETRIES = 3

  def self.new
    configuration = ThinkingSphinx::Configuration.instance
    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    address = configuration.searchd.address || '127.0.0.1'
    address = '127.0.0.1' if address == 'localhost'

    options = {
      :host      => address,
      :port      => configuration.searchd.mysql41,
      :reconnect => true
    }.merge(configuration.settings['connection_options'] || {})

    connection_class.new options
  end

  def self.connection_class
    return ThinkingSphinx::Connection::JRuby if RUBY_PLATFORM == 'java'

    ThinkingSphinx::Connection::MRI
  end

  def self.pool
    @pool ||= Innertube::Pool.new(
      Proc.new { ThinkingSphinx::Connection.new },
      Proc.new { |connection| connection.close! }
    )
  end

  def self.take
    retries  = 0
    original = nil
    begin
      pool.take do |connection|
        begin
          yield connection
        rescue ThinkingSphinx::QueryExecutionError, connection.base_error => error
          original = ThinkingSphinx::SphinxError.new_from_mysql error
          retries += MAXIMUM_RETRIES if original.is_a?(ThinkingSphinx::QueryError)
          raise Innertube::Pool::BadResource
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1
      raise original unless retries < MAXIMUM_RETRIES

      ActiveSupport::Notifications.instrument(
        "message.thinking_sphinx", :message => "Retrying query \"#{original.statement}\" after error: #{original.message}"
      )
      retry
    end
  end

  def self.persistent?
    @persistent
  end

  def self.persistent=(persist)
    @persistent = persist
  end

  @persistent = true
end

require 'thinking_sphinx/connection/client'
require 'thinking_sphinx/connection/jruby'
require 'thinking_sphinx/connection/mri'
