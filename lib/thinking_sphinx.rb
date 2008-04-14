require 'active_record'
require 'riddle'

require 'thinking_sphinx/active_record'
require 'thinking_sphinx/association'
require 'thinking_sphinx/attribute'
require 'thinking_sphinx/field'
require 'thinking_sphinx/index'
require 'thinking_sphinx/search'

ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)

module ThinkingSphinx
  module Version #:nodoc:
    Major = 0
    Minor = 9
    Tiny  = 0
    
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
end