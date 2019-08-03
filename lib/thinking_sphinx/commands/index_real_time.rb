# frozen_string_literal: true

class ThinkingSphinx::Commands::IndexRealTime < ThinkingSphinx::Commands::Base
  def call
    ThinkingSphinx::RealTime.processor.call options[:indices] do
      command :rotate
    end
  end

  private

  def type
    'indexing'
  end
end
