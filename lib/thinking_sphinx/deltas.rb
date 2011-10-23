module ThinkingSphinx::Deltas
  def self.processor_for(delta)
    case delta
    when TrueClass
      ThinkingSphinx::Deltas::DefaultDelta
    when Class
      delta
    else
      nil
    end
  end
end

require 'thinking_sphinx/deltas/default_delta'
