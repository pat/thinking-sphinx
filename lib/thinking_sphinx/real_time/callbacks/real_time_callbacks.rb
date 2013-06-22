class ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks
  def initialize(reference, path = [])
    @reference, @path = reference, path
  end

  def after_save(instance)
    return unless real_time_indices?

    real_time_indices.each do |index|
      ThinkingSphinx::RealTime::Transcriber.new(index).copy object_for(instance)
    end
  end

  private

  attr_reader :reference, :path

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def indices
    @indices ||= configuration.indices_for_references reference
  end

  def object_for(instance)
    path.inject(instance) { |object, method| object.send method }
  end

  def real_time_indices?
    real_time_indices.any?
  end

  def real_time_indices
    @real_time_indices ||= indices.select { |index|
      index.is_a? ThinkingSphinx::RealTime::Index
    }
  end
end
