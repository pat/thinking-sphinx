require 'active_record'
require 'riddle'

require 'thinking_sphinx/active_record'
require 'thinking_sphinx/association'
require 'thinking_sphinx/attribute'
require 'thinking_sphinx/configuration'
require 'thinking_sphinx/field'
require 'thinking_sphinx/index'
require 'thinking_sphinx/rails_additions'
require 'thinking_sphinx/search'

ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)

Merb::Plugins.add_rakefiles(
  File.join(File.dirname(__FILE__), "..", "tasks", "thinking_sphinx_tasks")
) if defined?(Merb)

module ThinkingSphinx
  module Version #:nodoc:
    Major = 0
    Minor = 9
    Tiny  = 2
    
    String = [Major, Minor, Tiny].join('.')
  end
  
  # A ConnectionError will get thrown when a connection to Sphinx can't be
  # made.
  class ConnectionError < StandardError
  end
  
  # The collection of indexed models. Keep in mind that Rails lazily loads
  # its classes, so this may not actually be populated with _all_ the models
  # that have Sphinx indexes.
  def self.indexed_models
    @@indexed_models ||= []
  end
  
  def self.indexed_models=(value) #:nodoc:
    @@indexed_models = value
  end
  
  # Check if index definition is disabled.
  # 
  def self.define_indexes?
    @@define_indexes =  true unless defined?(@@define_indexes)
    @@define_indexes == true
  end
  
  # Enable/disable indexes - you may want to do this while migrating data.
  # 
  #   ThinkingSphinx.define_indexes = false
  # 
  def self.define_indexes=(value)
    @@define_indexes = value
  end
  
  # Check if delta indexing is enabled.
  # 
  def self.deltas_enabled?
    @@deltas_enabled =  true unless defined?(@@deltas_enabled)
    @@deltas_enabled == true
  end
  
  # Enable/disable all delta indexing.
  #
  #   ThinkingSphinx.deltas_enabled = false
  #
  def self.deltas_enabled=(value)
    @@deltas_enabled = value
  end
end