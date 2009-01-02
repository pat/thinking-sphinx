require 'delayed/job'

require 'thinking_sphinx/deltas/delayed_delta/delta_job'
require 'thinking_sphinx/deltas/delayed_delta/job'

module ThinkingSphinx
  module Deltas
    class DelayedDelta < ThinkingSphinx::Deltas::DefaultDelta
      def index(model, instance = nil)
        ThinkingSphinx::Deltas::Job.enqueue(
          ThinkingSphinx::Deltas::DeltaJob.new(model)
        )
        
        true
      end
    end
  end
end
