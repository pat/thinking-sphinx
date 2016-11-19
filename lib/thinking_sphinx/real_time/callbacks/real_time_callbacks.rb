class ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks
  def initialize(reference, path = [], &block)
    @reference, @path, @block = reference, path, block
  end

  def after_commit(instance)
    persist_changes instance
  end

  def after_save(instance)
    persist_changes instance
  end

  private

  attr_reader :reference, :path, :block

  def callbacks_enabled?
    setting = configuration.settings['real_time_callbacks']
    setting.nil? || setting
  end

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def indices
    configuration.indices_for_references reference
  end

  def objects_for(instance)
    if block
      results = block.call instance
    else
      results = path.inject(instance) { |object, method| object.send method }
    end

    Array results
  end

  def persist_changes(instance)
    return unless real_time_indices? && callbacks_enabled?

    real_time_indices.each do |index|
      objects_for(instance).each do |object|
        ThinkingSphinx::RealTime::Transcriber.new(index).copy object
      end
    end
  end

  def real_time_indices?
    real_time_indices.any?
  end

  def real_time_indices
    indices.select { |index| index.is_a? ThinkingSphinx::RealTime::Index }
  end
end
