class ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
  attr_reader :instance

  def self.after_commit(instance)
    new(instance).after_commit
  end

  def self.before_save(instance)
    new(instance).before_save
  end

  def initialize(instance)
    @instance = instance
  end

  def after_commit
    return unless delta_indices? && instance.delta?

    config.controller.index *delta_indices.collect(&:name)
  end

  def before_save
    return unless delta_indices?

    instance.delta = true
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end

  def delta_indices
    @delta_indices ||= indices.select { |index| index.delta? }
  end

  def delta_indices?
    delta_indices.any?
  end

  def indices
    @indices ||= config.indices_for_reference reference
  end

  def reference
    instance.class.name.underscore.to_sym
  end
end
