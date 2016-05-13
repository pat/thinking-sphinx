class JSONColumn
  def self.call
    new.call
  end

  def call
    postgresql? && column?
  end

  private

  def column?
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::TableDefinition.
      instance_methods.include?(:json)
  end

  def postgresql?
    ENV['DATABASE'] == 'postgresql'
  end
end
