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
    suspend!
    yield
    resume!

    config.indices_for_references(reference).each do |index|
      index.delta_processor.index index
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
