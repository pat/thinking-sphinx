module AfterCommit
  def self.record(connection, record)
    Thread.current[:committed_records] ||= {}
    Thread.current[:committed_records][connection.object_id] ||= []
    Thread.current[:committed_records][connection.object_id] << record
  end

  def self.record_created(connection, record)
    Thread.current[:committed_records_on_create] ||= {}
    Thread.current[:committed_records_on_create][connection.object_id] ||= []
    Thread.current[:committed_records_on_create][connection.object_id] << record
  end

  def self.record_updated(connection, record)
    Thread.current[:committed_records_on_update] ||= {}
    Thread.current[:committed_records_on_update][connection.object_id] ||= []
    Thread.current[:committed_records_on_update][connection.object_id] << record
  end

  def self.record_destroyed(connection, record)
    Thread.current[:committed_records_on_destroy] ||= {}
    Thread.current[:committed_records_on_destroy][connection.object_id] ||= []
    Thread.current[:committed_records_on_destroy][connection.object_id] << record
  end

  def self.created_records(connection)
    Thread.current[:committed_records_on_create] ||= {}
    Thread.current[:committed_records_on_create][connection.object_id] ||= []
  end

  def self.updated_records(connection)
    Thread.current[:committed_records_on_update] ||= {}
    Thread.current[:committed_records_on_update][connection.object_id] ||= []
  end

  def self.destroyed_records(connection)
    Thread.current[:committed_records_on_destroy] ||= {}
    Thread.current[:committed_records_on_destroy][connection.object_id] ||= []
  end

  def self.records(connection)
    Thread.current[:committed_records] ||= {}
    Thread.current[:committed_records][connection.object_id] ||= []
  end

  def self.cleanup(connection)
    Thread.current[:committed_records]            = {}
    Thread.current[:committed_records_on_create]  = {}
    Thread.current[:committed_records_on_update]  = {}
    Thread.current[:committed_records_on_destroy] = {}
  end
end

require 'after_commit/active_record'
require 'after_commit/connection_adapters'

ActiveRecord::Base.send(:include, AfterCommit::ActiveRecord)

Object.subclasses_of(ActiveRecord::ConnectionAdapters::AbstractAdapter).each do |klass|
  klass.send(:include, AfterCommit::ConnectionAdapters)
end

if defined?(JRUBY_VERSION) and defined?(JdbcSpec::MySQL)
  JdbcSpec::MySQL.send :include, AfterCommit::ConnectionAdapters
end
