require 'thread'
require 'active_record'
require 'after_commit'
require 'yaml'
require 'riddle'

require 'thinking_sphinx/auto_version'
require 'thinking_sphinx/core/string'
require 'thinking_sphinx/property'
require 'thinking_sphinx/active_record'
require 'thinking_sphinx/association'
require 'thinking_sphinx/attribute'
require 'thinking_sphinx/bundled_search'
require 'thinking_sphinx/configuration'
require 'thinking_sphinx/context'
require 'thinking_sphinx/excerpter'
require 'thinking_sphinx/facet'
require 'thinking_sphinx/class_facet'
require 'thinking_sphinx/facet_search'
require 'thinking_sphinx/field'
require 'thinking_sphinx/index'
require 'thinking_sphinx/join'
require 'thinking_sphinx/source'
require 'thinking_sphinx/rails_additions'
require 'thinking_sphinx/search'
require 'thinking_sphinx/search_methods'
require 'thinking_sphinx/deltas'

require 'thinking_sphinx/adapters/abstract_adapter'
require 'thinking_sphinx/adapters/mysql_adapter'
require 'thinking_sphinx/adapters/postgresql_adapter'

ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)

Merb::Plugins.add_rakefiles(
  File.join(File.dirname(__FILE__), "thinking_sphinx", "tasks")
) if defined?(Merb)

module ThinkingSphinx
  mattr_accessor :database_adapter
  
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
  
  # A SphinxError occurs when Sphinx responds with an error due to problematic
  # queries or indexes.
  class SphinxError < RuntimeError
    attr_accessor :results
    def initialize(message = nil, results = nil)
      super(message)
      self.results = results
    end
  end
  
  # The current version of Thinking Sphinx.
  # 
  # @return [String] The version number as a string
  # 
  def self.version
    open(File.join(File.dirname(__FILE__), '../VERSION')) { |f|
      f.read.strip
    }
  end
  
  # The collection of indexed models. Keep in mind that Rails lazily loads
  # its classes, so this may not actually be populated with _all_ the models
  # that have Sphinx indexes.
  @@sphinx_mutex          = Mutex.new
  @@context               = nil
  @@define_indexes        = true
  @@deltas_enabled        = nil
  @@updates_enabled       = nil
  @@suppress_delta_output = false
  @@remote_sphinx         = false
  @@use_group_by_shortcut = nil
  
  def self.mutex
    @@sphinx_mutex
  end
  
  def self.context
    if @@context.nil?
      mutex.synchronize do
        if @@context.nil?
          @@context = ThinkingSphinx::Context.new
          @@context.prepare
        end
      end
    end
    
    @@context
  end
  
  def self.reset_context!(context = nil)
    mutex.synchronize do
      @@context = context
    end
  end

  def self.unique_id_expression(adapter, offset = nil)
    "* #{adapter.cast_to_int context.indexed_models.size} + #{offset || 0}"
  end

  # Check if index definition is disabled.
  #
  def self.define_indexes?
    @@define_indexes
  end

  # Enable/disable indexes - you may want to do this while migrating data.
  #
  #   ThinkingSphinx.define_indexes = false
  #
  def self.define_indexes=(value)
    mutex.synchronize do
      @@define_indexes = value
    end
  end
  
  # Check if delta indexing is enabled/disabled.
  #
  def self.deltas_enabled?
    if @@deltas_enabled.nil?
      mutex.synchronize do
        if @@deltas_enabled.nil?
          @@deltas_enabled = (
            ThinkingSphinx::Configuration.environment != "test"
          )
        end
      end
    end
    
    @@deltas_enabled && !deltas_suspended?
  end
  
  # Enable/disable delta indexing.
  #
  #   ThinkingSphinx.deltas_enabled = false
  #
  def self.deltas_enabled=(value)
    mutex.synchronize do
      @@deltas_enabled = value
    end
  end

  # Check if delta indexing is suspended.
  #
  def self.deltas_suspended?
    if Thread.current[:thinking_sphinx_deltas_suspended].nil?
      Thread.current[:thinking_sphinx_deltas_suspended] = false
    end
    
    Thread.current[:thinking_sphinx_deltas_suspended]
  end

  # Suspend/resume delta indexing.
  #
  #   ThinkingSphinx.deltas_suspended = false
  #
  def self.deltas_suspended=(value)
    Thread.current[:thinking_sphinx_deltas_suspended] = value
  end

  # Check if updates are enabled. True by default, unless within the test
  # environment.
  #
  def self.updates_enabled?
    if @@updates_enabled.nil?
      mutex.synchronize do
        if @@updates_enabled.nil?
          @@updates_enabled = (
            ThinkingSphinx::Configuration.environment != "test"
          )
        end
      end
    end
    
    @@updates_enabled
  end

  # Enable/disable updates to Sphinx
  #
  #   ThinkingSphinx.updates_enabled = false
  #
  def self.updates_enabled=(value)
    mutex.synchronize do
      @@updates_enabled = value
    end
  end

  def self.suppress_delta_output?
    @@suppress_delta_output
  end

  def self.suppress_delta_output=(value)
    mutex.synchronize do
      @@suppress_delta_output = value
    end
  end
  
  # Checks to see if MySQL will allow simplistic GROUP BY statements. If not,
  # or if not using MySQL, this will return false.
  #
  def self.use_group_by_shortcut?
    if @@use_group_by_shortcut.nil?
      mutex.synchronize do
        if @@use_group_by_shortcut.nil?
          @@use_group_by_shortcut = !!(
            mysql? && ::ActiveRecord::Base.connection.select_all(
              "SELECT @@global.sql_mode, @@session.sql_mode;"
            ).all? { |key, value|
              value.nil? || value[/ONLY_FULL_GROUP_BY/].nil?
            }
          )
        end
      end
    end
    
    @@use_group_by_shortcut
  end
  
  def self.reset_use_group_by_shortcut
    mutex.synchronize do
      @@use_group_by_shortcut = nil
    end
  end

  # An indication of whether Sphinx is running on a remote machine instead of
  # the same machine.
  #
  def self.remote_sphinx?
    @@remote_sphinx
  end

  # Tells Thinking Sphinx that Sphinx is running on a different machine, and
  # thus it can't reliably guess whether it is running or not (ie: the
  # #sphinx_running? method), and so just assumes it is.
  #
  # Useful for multi-machine deployments. Set it in your production.rb file.
  #
  #   ThinkingSphinx.remote_sphinx = true
  #
  def self.remote_sphinx=(value)
    mutex.synchronize do
      @@remote_sphinx = value
    end
  end

  # Check if Sphinx is running. If remote_sphinx is set to true (indicating
  # Sphinx is on a different machine), this will always return true, and you
  # will have to handle any connection errors yourself.
  #
  def self.sphinx_running?
    remote_sphinx? || sphinx_running_by_pid?
  end

  # Check if Sphinx is actually running, provided the pid is on the same
  # machine as this code.
  #
  def self.sphinx_running_by_pid?
    !!sphinx_pid && pid_active?(sphinx_pid)
  end

  def self.sphinx_pid
    if File.exists?(ThinkingSphinx::Configuration.instance.pid_file)
      File.read(ThinkingSphinx::Configuration.instance.pid_file)[/\d+/]
    else
      nil
    end
  end

  def self.pid_active?(pid)
    !!Process.kill(0, pid.to_i)
  rescue Errno::EPERM => e
    true
  rescue Exception => e
    false
  end

  def self.microsoft?
    RUBY_PLATFORM =~ /mswin/
  end

  def self.jruby?
    defined?(JRUBY_VERSION)
  end

  def self.mysql?
    ::ActiveRecord::Base.connection.class.name.demodulize == "MysqlAdapter" ||
    ::ActiveRecord::Base.connection.class.name.demodulize == "Mysql2Adapter" ||
    ::ActiveRecord::Base.connection.class.name.demodulize == "MysqlplusAdapter" || (
      jruby? && ::ActiveRecord::Base.connection.config[:adapter] == "jdbcmysql"
    )
  end
  
  extend ThinkingSphinx::SearchMethods::ClassMethods
end

ThinkingSphinx::AutoVersion.detect
