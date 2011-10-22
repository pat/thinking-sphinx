module ThinkingSphinx::Deltas
  def self.processor_for(delta)
    ThinkingSphinx::Deltas::DefaultDelta
  end
end

require 'thinking_sphinx/deltas/default_delta'
