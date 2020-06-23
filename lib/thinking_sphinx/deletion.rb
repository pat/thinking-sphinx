# frozen_string_literal: true

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

  def execute(statement)
    statement = statement.gsub(/\s*\n\s*/, ' ').strip

    ThinkingSphinx::Logger.log :query, statement do
      ThinkingSphinx::Connection.take do |connection|
        connection.execute statement
      end
    end
  end

  class PlainDeletion < ThinkingSphinx::Deletion
    def perform
      ids.each_slice(1000) do |some_ids|
        execute <<-SQL
UPDATE #{name}
SET sphinx_deleted = 1
WHERE sphinx_internal_id IN (#{some_ids.join(', ')})
        SQL
      end
    end
  end

  class RealtimeDeletion < ThinkingSphinx::Deletion
    def perform
      return unless callbacks_enabled?

      ids.each_slice(1000) do |some_ids|
        execute <<-SQL
DELETE FROM #{name}
WHERE sphinx_internal_id IN (#{some_ids.join(', ')})
        SQL
      end
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
end
