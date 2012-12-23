class ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks <
  ThinkingSphinx::Callbacks

  callbacks :after_save

  def after_save
    return unless real_time_indices?

    real_time_indices.each do |index|
      ThinkingSphinx::RealTime::Transcriber.new(index).copy instance
    end
  end

  private

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def indices
    @indices ||= configuration.indices_for_references reference
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
