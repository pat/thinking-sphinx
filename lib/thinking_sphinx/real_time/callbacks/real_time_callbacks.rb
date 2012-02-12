class ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks <
  ThinkingSphinx::Callbacks

  callbacks :after_save

  def after_save
    return unless real_time_indices?

    real_time_indices.each do |index|
      columns, values = ['id'], [index.document_id_for_key(instance.id)]
      (index.fields + index.attributes).each do |property|
        columns << property.name
        values  << property.translate(instance)
      end

      sphinxql = Riddle::Query::Insert.new(index.name, columns, values).replace!
      connection.query sphinxql.to_sql
    end
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end

  def connection
    connection = config.connection
  end

  def indices
    @indices ||= config.indices_for_references reference
  end

  def real_time_indices?
    real_time_indices.any?
  end

  def real_time_indices
    @real_time_indices ||= indices.select { |index|
      index.is_a? ThinkingSphinx::RealTime::Index
    }
  end

  def reference
    instance.class.name.underscore.to_sym
  end
end
