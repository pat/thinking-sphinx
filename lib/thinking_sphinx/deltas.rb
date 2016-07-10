module ThinkingSphinx::Deltas
  def self.config
    ThinkingSphinx::Configuration.instance
  end

  def self.processor_for(delta)
    case delta
    when TrueClass
      ThinkingSphinx::Deltas::DefaultDelta
    when Class
      delta
    when String
      delta.constantize
    else
      nil
    end
  end

  def self.resume!
    @suspended = false
  end

  def self.suspend(reference, &block)
    was_suspended = suspended?
    suspend!
    yield

    unless was_suspended
      resume!

      config.indices_for_references(reference).each do |index|
        index.delta_processor.index index if index.delta?
      end
    end
  end

  def self.suspend_and_update(reference, &block)
    suspend reference, &block

    ids = reference.to_s.camelize.constantize.where(delta: true).pluck(:id)
    config.indices_for_references(reference).each do |index|
      ThinkingSphinx::Deletion.perform index, ids unless index.delta?
    end
  end

  def self.suspend!
    @suspended = true
  end

  def self.suspended?
    @suspended
  end
end

require 'thinking_sphinx/deltas/default_delta'
require 'thinking_sphinx/deltas/delete_job'
require 'thinking_sphinx/deltas/index_job'
