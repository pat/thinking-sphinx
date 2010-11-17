require 'active_record'
require 'action_controller'
require 'yaml'
require 'riddle'

require 'thinking_sphinx/auto_version'
require 'thinking_sphinx/core/array'
require 'thinking_sphinx/core/string'
require 'thinking_sphinx/property'
require 'thinking_sphinx/active_record'
require 'thinking_sphinx/action_controller'
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
require 'thinking_sphinx/search'
require 'thinking_sphinx/search_methods'
require 'thinking_sphinx/deltas'

require 'thinking_sphinx/adapters/abstract_adapter'
require 'thinking_sphinx/adapters/mysql_adapter'
require 'thinking_sphinx/adapters/postgresql_adapter'

require 'thinking_sphinx/railtie' if defined?(Rails)

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
  @@sphinx_mutex = Mutex.new
  @@context      = nil
  
  def self.context
    if @@context.nil?
      @@sphinx_mutex.synchronize do
        if @@context.nil?
          @@context = ThinkingSphinx::Context.new
          @@context.prepare
        end
      end
    end
    
    @@context
  end
  
  def self.reset_context!
    @@sphinx_mutex.synchronize do
      @@context = nil
    end
  end

  def self.unique_id_expression(offset = nil)
    "* #{context.indexed_models.size} + #{offset || 0}"
  end

  # Check if index definition is disabled.
  #
  def self.define_indexes?
    if Thread.current[:thinking_sphinx_define_indexes].nil?
      Thread.current[:thinking_sphinx_define_indexes] = true
    end
    
    Thread.current[:thinking_sphinx_define_indexes]
  end

  # Enable/disable indexes - you may want to do this while migrating data.
  #
  #   ThinkingSphinx.define_indexes = false
  #
  def self.define_indexes=(value)
    Thread.current[:thinking_sphinx_define_indexes] = value
  end

  # Check if delta indexing is enabled.
  #
  def self.deltas_enabled?
    if Thread.current[:thinking_sphinx_deltas_enabled].nil?
      Thread.current[:thinking_sphinx_deltas_enabled] = (
        ThinkingSphinx::Configuration.environment != "test"
      )
    end
    
    Thread.current[:thinking_sphinx_deltas_enabled]
  end

  # Enable/disable all delta indexing.
  #
  #   ThinkingSphinx.deltas_enabled = false
  #
  def self.deltas_enabled=(value)
    Thread.current[:thinking_sphinx_deltas_enabled] = value
  end

  # Check if updates are enabled. True by default, unless within the test
  # environment.
  #
  def self.updates_enabled?
    if Thread.current[:thinking_sphinx_updates_enabled].nil?
      Thread.current[:thinking_sphinx_updates_enabled] = (
        ThinkingSphinx::Configuration.environment != "test"
      )
    end
    
    Thread.current[:thinking_sphinx_updates_enabled]
  end

  # Enable/disable updates to Sphinx
  #
  #   ThinkingSphinx.updates_enabled = false
  #
  def self.updates_enabled=(value)
    Thread.current[:thinking_sphinx_updates_enabled] = value
  end

  def self.suppress_delta_output?
    Thread.current[:thinking_sphinx_suppress_delta_output] ||= false
  end

  def self.suppress_delta_output=(value)
    Thread.current[:thinking_sphinx_suppress_delta_output] = value
  end
  
  # Checks to see if MySQL will allow simplistic GROUP BY statements. If not,
  # or if not using MySQL, this will return false.
  #
  def self.use_group_by_shortcut?
    if Thread.current[:thinking_sphinx_use_group_by_shortcut].nil?
      Thread.current[:thinking_sphinx_use_group_by_shortcut] = !!(
        mysql? && ::ActiveRecord::Base.connection.select_all(
          "SELECT @@global.sql_mode, @@session.sql_mode;"
        ).all? { |key,value| value.nil? || value[/ONLY_FULL_GROUP_BY/].nil? }
      )
    end
    
    Thread.current[:thinking_sphinx_use_group_by_shortcut]
  end

  # An indication of whether Sphinx is running on a remote machine instead of
  # the same machine.
  #
  def self.remote_sphinx?
    Thread.current[:thinking_sphinx_remote_sphinx] ||= false
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
    Thread.current[:thinking_sphinx_remote_sphinx] = value
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
    ::ActiveRecord::Base.connection.class.name.demodulize == "MysqlplusAdapter" || (
      jruby? && ::ActiveRecord::Base.connection.config[:adapter] == "jdbcmysql"
    )
  end
  
  extend ThinkingSphinx::SearchMethods::ClassMethods
end

ThinkingSphinx::AutoVersion.detect
