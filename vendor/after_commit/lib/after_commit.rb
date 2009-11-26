module AfterCommit
  def self.record(connection, record)
    prepare_collection :committed_records, connection
    add_to_collection  :committed_records, connection, record
  end

  def self.record_created(connection, record)
    prepare_collection :committed_records_on_create, connection
    add_to_collection  :committed_records_on_create, connection, record
  end

  def self.record_updated(connection, record)
    prepare_collection :committed_records_on_update, connection
    add_to_collection  :committed_records_on_update, connection, record
  end

  def self.record_destroyed(connection, record)
    prepare_collection :committed_records_on_destroy, connection
    add_to_collection  :committed_records_on_destroy, connection, record
  end
  
  def self.records(connection)
    collection :committed_records, connection
  end

  def self.created_records(connection)
    collection :committed_records_on_create, connection
  end

  def self.updated_records(connection)
    collection :committed_records_on_update, connection
  end

  def self.destroyed_records(connection)
    collection :committed_records_on_destroy, connection
  end

  def self.cleanup(connection)
    [
      :committed_records,
      :committed_records_on_create,
      :committed_records_on_update,
      :committed_records_on_destroy
    ].each do |collection|
      Thread.current[collection]                        ||= {}
      Thread.current[collection][connection.old_transaction_key] = []
    end
  end
  
  def self.prepare_collection(collection, connection)
    Thread.current[collection] ||= {}
    Thread.current[collection][connection.unique_transaction_key] ||= []
  end
  
  def self.add_to_collection(collection, connection, record)
    Thread.current[collection][connection.unique_transaction_key] << record
  end
  
  def self.collection(collection, connection)
    Thread.current[collection] ||= {}
    Thread.current[collection][connection.old_transaction_key] ||= []
  end
end

require 'after_commit/active_record'
require 'after_commit/connection_adapters'
require 'after_commit/test_bypass'

ActiveRecord::Base.send(:include, AfterCommit::ActiveRecord)
ActiveRecord::Base.include_after_commit_extensions
