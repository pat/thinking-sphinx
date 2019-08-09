# frozen_string_literal: true

class ThinkingSphinx::RealTime::Processor
  def self.call(indices, &block)
    new(indices).call(&block)
  end

  def initialize(indices)
    @indices = indices
  end

  def call(&block)
    subscribe_to_progress

    indices.each do |index|
      ThinkingSphinx::RealTime.populator.populate index

      block.call
    end
  end

  private

  attr_reader :indices

  def command
    ThinkingSphinx::Commander.call(
      command, configuration, options, stream
    )
  end

  def subscribe_to_progress
    ThinkingSphinx::Subscribers::PopulatorSubscriber.
      attach_to 'thinking_sphinx.real_time'
  end
end
