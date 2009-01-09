Dir[File.join(File.dirname(__FILE__), '../vendor/*/lib')].each do |path|
  $LOAD_PATH.unshift path
end

require 'active_record'
require 'riddle'
require 'after_commit'

require 'thinking_sphinx/core/string'
require 'thinking_sphinx/active_record'
require 'thinking_sphinx/association'
require 'thinking_sphinx/attribute'
require 'thinking_sphinx/collection'
require 'thinking_sphinx/configuration'
require 'thinking_sphinx/field'
require 'thinking_sphinx/index'
require 'thinking_sphinx/rails_additions'
require 'thinking_sphinx/search'
require 'thinking_sphinx/deltas'

require 'thinking_sphinx/adapters/abstract_adapter'
require 'thinking_sphinx/adapters/mysql_adapter'
require 'thinking_sphinx/adapters/postgresql_adapter'

ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)

Merb::Plugins.add_rakefiles(
  File.join(File.dirname(__FILE__), "..", "tasks", "thinking_sphinx_tasks")
) if defined?(Merb)

module ThinkingSphinx
  module Version #:nodoc:
    Major = 1
    Minor = 1
    Tiny  = 2
    
    String = [Major, Minor, Tiny].join('.')
  end
  
  # A ConnectionError will get thrown when a connection to Sphinx can't be
  # made.
  class ConnectionError < StandardError
  end
  
  # A StaleIdsException is thrown by Collection.instances_from_matches if there
  # are records in Sphinx but not in the database, so the search can be retried.
  class StaleIdsException < StandardError
    attr_accessor :ids
    def initialize(ids)
      self.ids = ids
    end
  end
  
  # The collection of indexed models. Keep in mind that Rails lazily loads
  # its classes, so this may not actually be populated with _all_ the models
  # that have Sphinx indexes.
  def self.indexed_models
    @@indexed_models ||= []
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
  
  @@deltas_enabled = nil

  # Check if delta indexing is enabled.
  # 
  def self.deltas_enabled?
    @@deltas_enabled  = (ThinkingSphinx::Configuration.environment != 'test') if @@deltas_enabled.nil?
    @@deltas_enabled
  end
  
  # Enable/disable all delta indexing.
  #
  #   ThinkingSphinx.deltas_enabled = false
  #
  def self.deltas_enabled=(value)
    @@deltas_enabled = value
  end
  
  @@updates_enabled = nil
  
  # Check if updates are enabled. True by default, unless within the test
  # environment.
  # 
  def self.updates_enabled?
    @@updates_enabled  = (ThinkingSphinx::Configuration.environment != 'test') if @@updates_enabled.nil?
    @@updates_enabled
  end
  
  # Enable/disable updates to Sphinx
  # 
  #   ThinkingSphinx.updates_enabled = false
  #
  def self.updates_enabled=(value)
    @@updates_enabled = value
  end
  
  @@suppress_delta_output = false
  
  def self.suppress_delta_output?
    @@suppress_delta_output
  end
  
  def self.suppress_delta_output=(value)
    @@suppress_delta_output = value
  end
  
  # Checks to see if MySQL will allow simplistic GROUP BY statements. If not,
  # or if not using MySQL, this will return false.
  # 
  def self.use_group_by_shortcut?
    ::ActiveRecord::ConnectionAdapters.constants.include?("MysqlAdapter") &&
    ::ActiveRecord::Base.connection.is_a?(
      ::ActiveRecord::ConnectionAdapters::MysqlAdapter
    ) &&
    ::ActiveRecord::Base.connection.select_all(
      "SELECT @@global.sql_mode, @@session.sql_mode;"
    ).all? { |key,value| value.nil? || value[/ONLY_FULL_GROUP_BY/].nil? }
  end
  
  def self.sphinx_running?
    !!sphinx_pid
  end
  
  def self.sphinx_pid
    pid_file = ThinkingSphinx::Configuration.instance.pid_file    
    `cat #{pid_file}`[/\d+/] if File.exists?(pid_file)
  end
end
