require 'thread'
require 'socket'
require 'timeout'

module Riddle #:nodoc:
  @@mutex          = Mutex.new
  @@escape_pattern = /[\(\)\|\-!@~"&\/]/
  @@use_encoding   = defined?(::Encoding) &&
                     ::Encoding.respond_to?(:default_external)
  
  class ConnectionError < StandardError #:nodoc:
    #
  end

  def self.encode(data, encoding = defined?(::Encoding) && ::Encoding.default_external)
    if @@use_encoding
      data.force_encoding(encoding)
    else
      data
    end
  end
  
  def self.mutex
    @@mutex
  end
  
  def self.escape_pattern
    @@escape_pattern
  end
  
  def self.escape_pattern=(pattern)
    mutex.synchronize do
      @@escape_pattern = pattern
    end
  end
  
  def self.escape(string)
    string.gsub(escape_pattern) { |char| "\\#{char}" }
  end
  
  def self.loaded_version
    @@sphinx_version
  end
  
  def self.loaded_version=(version)
    @@sphinx_version = version
  end
  
  def self.version_warning
    return if loaded_version
    
    STDERR.puts %Q{
Riddle cannot detect Sphinx on your machine, and so can't determine which
version of Sphinx you are planning on using. Please use one of the following
lines after "require 'riddle'" to avoid this warning.

  require 'riddle/0.9.8'
  # or
  require 'riddle/0.9.9'
  # or
  require 'riddle/1.10'

    }
  end

end

require 'riddle/auto_version'
require 'riddle/client'
require 'riddle/configuration'
require 'riddle/controller'
require 'riddle/query'
require 'riddle/version'

Riddle.loaded_version = nil
Riddle::AutoVersion.configure
