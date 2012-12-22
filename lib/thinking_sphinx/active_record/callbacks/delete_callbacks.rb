class ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks <
  ThinkingSphinx::Callbacks

  callbacks :after_destroy

  def after_destroy
    indices.each do |index|
      connection.execute Riddle::Query.update(
        index.name, index.document_id_for_key(instance.id),
        :sphinx_deleted => true
      )
    end
  rescue Mysql2::Error => error
    # This isn't vital, so don't raise the error.
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end

  def connection
    @connection ||= ThinkingSphinx::Connection.new
  end

  def indices
    config.preload_indices
    config.indices_for_references instance.class.name.underscore.to_sym
  end
end
