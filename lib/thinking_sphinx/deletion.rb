class ThinkingSphinx::Deletion
  delegate :name, :to => :index

  def self.perform(index, ids)
    return if index.distributed?

    {
      'plain' => PlainDeletion,
      'rt'    => RealtimeDeletion
    }[index.type].new(index, ids).perform
  rescue ThinkingSphinx::ConnectionError => error
    # This isn't vital, so don't raise the error.
  end

  def initialize(index, ids)
    @index, @ids = index, Array(ids)
  end

  private

  attr_reader :index, :ids

  def document_ids_for_keys
    ids.collect { |id| index.document_id_for_key id }
  end

  def execute(statement)
    statement = statement.gsub(/\s*\n\s*/, ' ')

    ThinkingSphinx::Logger.log :query, statement do
      ThinkingSphinx::Connection.take do |connection|
        connection.execute statement
      end
    end
  end

  class RealtimeDeletion < ThinkingSphinx::Deletion
    def perform
      return unless callbacks_enabled?

      execute Riddle::Query::Delete.new(name, document_ids_for_keys).to_sql
    end

    private

    def callbacks_enabled?
      setting = configuration.settings['real_time_callbacks']
      setting.nil? || setting
    end

    def configuration
      ThinkingSphinx::Configuration.instance
    end
  end

  class PlainDeletion < ThinkingSphinx::Deletion
    def perform
      document_ids_for_keys.each_slice(1000) do |document_ids|
        execute <<-SQL
UPDATE #{name}
SET sphinx_deleted = 1
WHERE id IN (#{document_ids.join(', ')})
        SQL
      end
    end
  end
end
